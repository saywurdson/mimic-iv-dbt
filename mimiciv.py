import os
import subprocess
import concurrent.futures
from getpass import getpass
import glob
import duckdb
from tqdm import tqdm
import pandas as pd

def download_data(url, download_directory, username, password):
    # Check if any .csv.gz files already exist in the download directory
    if os.path.exists(download_directory) and glob.glob(os.path.join(download_directory, '**', '*.csv.gz'), recursive=True):
        print(f"Data already downloaded for {url}, skipping...")
        return

    print(f"Starting download from: {url}")
    os.makedirs(download_directory, exist_ok=True)
    
    # Construct wget command
    command = ["wget", "-r", "-N", "-c", "-np", url]
    if username and password:
        command.extend(["--user", username, "--password", password])

    # Run the command
    subprocess.run(command, cwd=download_directory)

def upload_csv_to_duckdb(con, directory, schema_name):
    # Ensure the directory exists
    if not os.path.exists(directory):
        print(f"Directory does not exist: {directory}")
        return

    # Create the specified schema if it doesn't exist
    con.execute(f"CREATE SCHEMA IF NOT EXISTS {schema_name}")
    print(f"Schema '{schema_name}' created or already exists.")

    # Find all .csv.gz files in the directory
    csv_files = glob.glob(os.path.join(directory, '**', '*.csv.gz'), recursive=True)
    if not csv_files:
        print(f"No .csv.gz files found in directory {directory}")
        return  # If no files are found, return early

    for file in tqdm(csv_files, desc=f"Uploading files to {schema_name}"):
        # Extract table name from file name
        table_name = os.path.splitext(os.path.splitext(os.path.basename(file))[0])[0]
        print(f"Creating table {table_name} from file {file} in schema {schema_name}...")
        
        try:
            # Specify options and attempt to create table from the CSV file
            con.execute(f"""
                CREATE TABLE IF NOT EXISTS "{schema_name}.{table_name}" AS 
                SELECT * FROM read_csv('{file}', SAMPLE_SIZE=-1, AUTO_DETECT=TRUE)
            """)
        except Exception as e:
            print(f"Failed to create table {table_name} from file {file}: {e}")

def process_reference_tables(seed_directory, db_name):
    # Ensure the seed directory exists
    if not os.path.exists(seed_directory):
        print(f"Seed directory does not exist: {seed_directory}")
        return

    # Connect to DuckDB
    con = duckdb.connect(db_name)

    # Collect all CSV files in the seed directory
    all_files = os.listdir(seed_directory)
    csv_files = [f for f in all_files if f.endswith('.csv')]

    # If no CSV files found, print a message and exit the function
    if not csv_files:
        print("No CSV files found in the seed directory.")
        con.close()
        return

    # Process each CSV file
    for file in tqdm(csv_files, desc="Processing Reference files"):
        file_path = os.path.join(seed_directory, file)
        try:
            df = pd.read_csv(file_path, delimiter='\t', low_memory=False)  # Ensure delimiter matches file format
            dataframe_name = os.path.splitext(file)[0].lower()

            # Create schema and table in DuckDB
            table_name = f"reference.{dataframe_name}"
            con.execute(f"CREATE SCHEMA IF NOT EXISTS reference")
            con.register(f"{dataframe_name}_df", df)
            con.execute(f"CREATE TABLE IF NOT EXISTS {table_name} AS SELECT * FROM {dataframe_name}_df")

        except Exception as e:  # Catching any exception that might occur and print it
            print(f"Error processing file '{file}': {e}")

    # Close the database connection
    con.close()

def main():
    # Base directory for downloads
    base_download_directory = "/workspaces/dbt_mimic_iv/mimiciv"

    # Database file location
    db_name = "/workspaces/dbt_mimic_iv/mimiciv.db"

    # Check for existing files and prompt for credentials if necessary
    need_credentials = False
    downloads = [
        {"url": "https://physionet.org/files/mimiciv/2.2/", "dir": "mimiciv"},
        {"url": "https://physionet.org/files/mimic-iv-ed/2.2/", "dir": "mimic-iv-ed"},
        {"url": "https://physionet.org/files/mimic-iv-note/2.2/", "dir": "mimic-iv-note"}
    ]

    for download in downloads:
        download_dir = os.path.join(base_download_directory, download["dir"])
        if not os.path.exists(download_dir) or not glob.glob(os.path.join(download_dir, '*.csv.gz')):
            need_credentials = True
            break

    if need_credentials:
        # Get username and password only if needed
        username = input("Enter your username: ")
        password = getpass("Enter your password: ")
    else:
        username = None
        password = None

    # Connect to DuckDB
    con = duckdb.connect(db_name)

    # Start the download and upload process
    with concurrent.futures.ThreadPoolExecutor(max_workers=len(downloads)) as executor:
        futures = []
        for download in downloads:
            download_dir = os.path.join(base_download_directory, download["dir"])
            futures.append(
                executor.submit(download_data, download['url'], download_dir, username, password)
            )

        # Wait for all threads to complete
        for future in concurrent.futures.as_completed(futures):
            future.result()

    # Directory containing the reference files
    seed_directory = '/workspaces/dbt_mimic_iv/omop/seeds'

    # Specify directories and their corresponding schemas
    directories_and_schemas = {
        os.path.join(base_download_directory, "mimic-iv-ed"): "raw_ed",
        os.path.join(base_download_directory, "mimic-iv-note"): "raw_note",
        os.path.join(base_download_directory, "mimiciv"): "raw_hosp",
        os.path.join(base_download_directory, "mimiciv"): "raw_icu"
    }

    # Upload data to DuckDB
    for directory, schema in directories_and_schemas.items():
        upload_csv_to_duckdb(con, directory, schema)

    # Process reference tables if necessary
    process_reference_tables(seed_directory, db_name)

    # Close the database connection
    con.close()

    print("Process completed successfully.")

if __name__ == "__main__":
    main()