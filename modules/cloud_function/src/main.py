import pandas as pd
from google.cloud import storage
from google.cloud import secretmanager
import io
import os
import psycopg2
from psycopg2 import sql
from datetime import datetime
import logging
import urllib.parse



logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)


def log_message(message: str, level: str = 'INFO') -> None:
    """Log a message to the logger."""
    if os.getenv('RUN_ENV') == 'dev':
        print(message)
    else:
        log_method = getattr(logger, level.lower(), logger.info)
        log_method(f'{level}:: {message}')


def etl(event, context):

    """Cloud Function to be triggered by .csv file in bucket."""
    file_data = event
    bucket_name = file_data['bucket']
    file_name = file_data['name']
    file_size = file_data['size']

    log_message(f"File uploaded: {file_name} in bucket: {bucket_name}")
    log_message(f"File size: {file_size} bytes")

    log_message("ETL process starting", 'INFO')

    if not file_name.endswith('.csv'):
        log_message(f"{file_name} is not a CSV file. Skipping processing.")
        return

    log_message(f"Processing file: {file_name} in bucket: {bucket_name}")

    try:

        # Extraction
        storage_client = storage.Client()
        bucket = storage_client.bucket(bucket_name)
        blob = bucket.blob(file_name)
        csv_content = blob.download_as_string().decode('utf-8')
        df = pd.read_csv(io.StringIO(csv_content))

        # log_message(f"DataFrame from {file_name}:\n{df.head()}")

        # Transform
        query = query_generator(df, file_name)

        # Load
        if query:
            execute_query(query)

    except Exception as e:
        log_message(message=getattr(e, 'message', str(e)), level='ERROR')


def query_generator(df, file_name: str = 'file_name.csv'):
    # Define a mapping of file patterns to ETL functions
    etl_functions = {
        'AGE_MONTHLY.csv': process_age_monthly,
        'HOME_REACH_MONTHLY.csv': process_home_reach_monthly,
        'WORK_REACH_MONTHLY.csv': process_work_reach_monthly,
        'REACH_MONTHLY.csv': process_reach_monthly,
        'DEVICE_MONTHLY.csv': process_device_monthly,
        'GENDER_MONTHLY.csv': process_gender_monthly,
        'NATIONALITY_MONTHLY.csv': process_nationality_monthly,
        'MOBILITY_TYPE_MONTHLY.csv': process_mobility_type_monthly,
        'WORK_AVG_DISTANCE_MONTHLY.csv': process_avg_work_distance,
        'HOME_AVG_DISTANCE_MONTHLY.csv': process_avg_home_distance,
        'REACH_HOURLY.csv': process_reach_hourly,
        'REACH_DAYS.csv': process_reach_days
    }

    # Determine the appropriate ETL function based on the file name
    for key, func in etl_functions.items():
        if file_name.endswith(key):
            log_message(
                f"Processing file: {file_name} using {func.__name__} etl"
            )
            return func(df)

    # Handle cases where no matching ETL function is found
    log_message(f"{file_name} does not have a ETL function. Skipping.")
    return None

def access_secret_version(secret_id: str):
    # Create a Secret Manager client
    client = secretmanager.SecretManagerServiceClient()

    # Define the project ID and secret ID
    project_id = os.getenv('PROJECT_ID')
    secret_version_id = "latest"    # Replace with the version of the secret, e.g., "latest" or "versions/1"

    # Build the resource name of the secret version
    secret_version_name = f"projects/{project_id}/secrets/{secret_id}/versions/{secret_version_id}"

    # Access the secret version
    response = client.access_secret_version(name=secret_version_name)

    # Get the secret payload
    secret_payload = response.payload.data.decode("utf-8")

    return secret_payload

def execute_query(query):
    try:
        # Get the database connection details from Secret Manager
        dbname = access_secret_version(f"MDI_DASHBOARD_DB_NAME")
        user = access_secret_version(f"MDI_DB_USER")
        password = access_secret_version(f"MDI_DB_PASSWORD")
        host = access_secret_version(f"MDI_DB_HOST")
        port = access_secret_version(f"MDI_DB_PORT")

        # Establish connection to your PostgreSQL database
        conn = psycopg2.connect(
            dbname=dbname,
            user=user,
            password=password,
            host=host,
            port=port
        )
        log_message(f"{conn.info}Connected to the database successfully.")

        # Create a cursor object
        cursor = conn.cursor()
        # Execute the query
        cursor.execute(sql.SQL(query))
        # Commit the transaction
        conn.commit()

        # Log the number of rows affected
        rows_affected = cursor.rowcount
        # Log successful execution
        log_message(f"Query executed. Rows affected: {rows_affected}.")

    except Exception as e:
        log_message(f"An error occurred: {e}")
        conn.rollback()
    finally:
        # Close the cursor and connection
        cursor.close()
        conn.close()


def process_age_monthly(df):
    # Initialize lists to store values for bulk insertion
    values_list = []

    for index, row in df.iterrows():
        # Extract and day from the date
        date = datetime.strptime(row['MONTH'], "%Y-%m-%d")
        month = date.month
        year = date.year
        schema = f"{year}_{str(month).zfill(2)}"

        if pd.isna(row['POLYGON_L8']):
            continue
        polygon = row['POLYGON_L8']
        age_group = row['AGE_GROUP']
        user_reach = row['USER_REACH']

        # Append the values to the list
        values_list.append((
            date.strftime('%Y-%m-%d'),  polygon, age_group, user_reach
        ))

    # Create the VALUES part of the SQL query
    values_part = ',\n'.join(
        f"('{date}', '{polygon}', '{age_group}', {user_reach})"
        for date,  polygon, age_group, user_reach in values_list
    )

    # Create the upsert query
    query = f"""
    SELECT create_schema_and_tables('{schema}');
    INSERT INTO "{schema}".age_wise_user_reaches (date, polygon, age_group, user_reach)
    VALUES {values_part}
    ON CONFLICT (polygon, age_group) DO NOTHING;
    """

    return query


def process_reach_monthly(df):
    # Initialize lists to store values for bulk insertion
    values_list = []

    for index, row in df.iterrows():
        # Extract month and year from the MONTH column (assuming format is "YYYY-MM")
        date = datetime.strptime(row['MONTH'], "%Y-%m-%d")
        month = date.month
        year = date.year
        schema = f"{year}_{str(month).zfill(2)}"

        # parse POLYGON_L8 as string, if null, then skip the iteration
        if pd.isna(row['POLYGON_L8']):
            continue
        polygon = row['POLYGON_L8']
        impressions = row['IMPRESSIONS']
        user_reach = row['USER_REACH']
        daily_avg_impressions = row['DAILY_AVERAGE_IMPRESSIONS']
        daily_avg_user_reach = row['DAILY_AVERAGE_USER_REACH']
        weekdays_impressions = row['WEEKDAYS_IMPRESSIONS']
        weekdays_user_reach = row['WEEKDAYS_USER_REACH']
        weekends_impressions = row['WEEKENDS_IMPRESSIONS']
        weekends_user_reach = row['WEEKENDS_USER_REACH']

        # Append the values to the list
        values_list.append((
            date.strftime('%Y-%m-%d'),  polygon, impressions, user_reach,
            daily_avg_impressions, daily_avg_user_reach, weekdays_impressions, weekdays_user_reach,
            weekends_impressions, weekends_user_reach
        ))

    # Create the VALUES part of the SQL query
    values_part = ',\n'.join(
        f"('{date}', '{polygon}', {impressions}, {user_reach}, {daily_avg_impressions}, {daily_avg_user_reach}, {weekdays_impressions}, {weekdays_user_reach}, {weekends_impressions}, {weekends_user_reach})"
        for date,  polygon, impressions, user_reach, daily_avg_impressions, daily_avg_user_reach, weekdays_impressions, weekdays_user_reach, weekends_impressions, weekends_user_reach in values_list
    )

    # Create the upsert query
    query = f"""
    SELECT create_schema_and_tables('{schema}');
    INSERT INTO "{schema}".monthly_overviews (date,  polygon, impressions, user_reach, daily_average_impressions, daily_average_user_reach, weekdays_impressions, weekdays_user_reach, weekends_impressions, weekends_user_reach)
    VALUES {values_part}
    ON CONFLICT (polygon) DO NOTHING;
    """

    return query


def process_device_monthly(df):
    # Initialize lists to store values for bulk insertion
    values_list = []

    for index, row in df.iterrows():
        # Extract month and year from the MONTH column (assuming format is "YYYY-MM-DD")
        date = datetime.strptime(row['MONTH'], "%Y-%m-%d")
        month = date.month
        year = date.year
        schema = f"{year}_{str(month).zfill(2)}"

        # Get other values with None handling
        if pd.isna(row['POLYGON_L8']):
            continue
        polygon = row['POLYGON_L8']
        device_brand = row['DEVICE_BRAND'] if pd.notna(row['DEVICE_BRAND']) else 'NULL'
        user_reach = row['USER_REACH'] if pd.notna(row['USER_REACH']) else 'NULL'

        # Append the values to the list
        values_list.append((
            date.strftime('%Y-%m-%d'), polygon, device_brand, user_reach
        ))

    # Create the VALUES part of the SQL query
    values_part = ',\n'.join(
        f"('{date}', '{polygon}', '{device_brand}', {user_reach} )"
        for date, polygon, device_brand, user_reach in values_list
    )

    # Create the insert query with ON CONFLICT DO NOTHING
    query = f"""
    SELECT create_schema_and_tables('{schema}');
    INSERT INTO "{schema}".device_types (date, polygon, device_brand, user_reach)
    VALUES {values_part}
    ON CONFLICT (polygon, device_brand) DO NOTHING;
    """

    return query


def process_gender_monthly(df):
    # Initialize a dictionary to aggregate the values for each polygon
    gender_data = {}

    for index, row in df.iterrows():
        # Extract month and year from the MONTH column
        date = datetime.strptime(row['MONTH'], "%Y-%m-%d")
        month = date.month
        year = date.year
        schema = f"{year}_{str(month).zfill(2)}"

        # Extract other values
        if pd.isna(row['POLYGON_L8']):
            continue
        polygon = row['POLYGON_L8']
        gender = row['GENDER'] if pd.notna(row['GENDER']) else 'OTHER'
        user_reach = row['USER_REACH'] if pd.notna(row['USER_REACH']) else 0

        # Initialize dictionary entry if it doesn't exist
        if (polygon) not in gender_data:
            gender_data[(polygon)] = {
                'date': date.strftime('%Y-%m-%d'),
                'gender_male_reaches': 0,
                'gender_female_reaches': 0,
                'gender_other_reaches': 0,
            }

        # Aggregate the user reach based on gender
        if gender == 'MALE':
            gender_data[(polygon)]['gender_male_reaches'] = user_reach
        elif gender == 'FEMALE':
            gender_data[(polygon)]['gender_female_reaches'] = user_reach
        else:
            gender_data[(polygon)]['gender_other_reaches'] = user_reach

    # Create the VALUES part of the SQL query
    values_list = []
    for (polygon), data in gender_data.items():
        values_list.append((
            data['date'], polygon, 
            data['gender_male_reaches'], data['gender_female_reaches'], data['gender_other_reaches']
        ))

    values_part = ',\n'.join(
        f"('{date}', '{polygon}', {gender_male_reaches}, {gender_female_reaches}, {gender_other_reaches})"
        for date, polygon, gender_male_reaches, gender_female_reaches, gender_other_reaches in values_list
    )

    # Create the upsert query
    query = f"""
    SELECT create_schema_and_tables('{schema}');
    INSERT INTO "{schema}".gender_nationality_user_reaches (date, polygon, gender_male_reaches, gender_female_reaches, gender_other_reaches)
    VALUES {values_part}
    ON CONFLICT ( polygon) DO UPDATE
    SET
        gender_male_reaches = EXCLUDED.gender_male_reaches,
        gender_female_reaches = EXCLUDED.gender_female_reaches,
        gender_other_reaches = EXCLUDED.gender_other_reaches;
    """

    return query


def process_nationality_monthly(df):
    # Initialize a dictionary to aggregate the values for each polygon
    nationality_data = {}

    for index, row in df.iterrows():
        # Extract month and year from the MONTH column
        date = datetime.strptime(row['MONTH'], "%Y-%m-%d")
        month = date.month
        year = date.year
        schema = f"{year}_{str(month).zfill(2)}"

        # Extract other values
        if pd.isna(row['POLYGON_L8']):
            continue
        polygon = row['POLYGON_L8']
        nationality = row['NATIONALITY'] if pd.notna(row['NATIONALITY']) else 'OTHER'
        user_reach = row['USER_REACH'] if pd.notna(row['USER_REACH']) else 0

        # Initialize dictionary entry if it doesn't exist
        if (polygon) not in nationality_data:
            nationality_data[(polygon)] = {
                'date': date.strftime('%Y-%m-%d'),
                'nationality_malaysian_reaches': 0,
                'nationality_non_malaysian_reaches': 0,
                'nationality_other_reaches': 0,
            }

        # Aggregate the user reach based on nationality
        if nationality == 'MALAYSIAN':
            nationality_data[(polygon)]['nationality_malaysian_reaches'] = user_reach
        elif nationality == 'NON-MALAYSIAN':
            nationality_data[(polygon)]['nationality_non_malaysian_reaches'] = user_reach
        else:
            nationality_data[(polygon)]['nationality_other_reaches'] = user_reach

    # Create the VALUES part of the SQL query
    values_list = []
    for (polygon), data in nationality_data.items():
        values_list.append((
            data['date'], polygon, 
            data['nationality_malaysian_reaches'], data['nationality_non_malaysian_reaches'], data['nationality_other_reaches']
        ))

    values_part = ',\n'.join(
        f"('{date}', '{polygon}', {nationality_malaysian_reaches}, {nationality_non_malaysian_reaches}, {nationality_other_reaches})"
        for date, polygon, nationality_malaysian_reaches, nationality_non_malaysian_reaches, nationality_other_reaches in values_list
    )

    # Create the upsert query
    query = f"""
    SELECT create_schema_and_tables('{schema}');
    INSERT INTO "{schema}".gender_nationality_user_reaches (date, polygon, nationality_malaysian_reaches, nationality_non_malaysian_reaches, nationality_other_reaches)
    VALUES {values_part}
    ON CONFLICT ( polygon) DO UPDATE SET
        nationality_malaysian_reaches = EXCLUDED.nationality_malaysian_reaches,
        nationality_non_malaysian_reaches = EXCLUDED.nationality_non_malaysian_reaches,
        nationality_other_reaches = EXCLUDED.nationality_other_reaches;
    """

    return query


def process_mobility_type_monthly(df):
    # Initialize a dictionary to aggregate the values for each polygon
    mobility_data = {}

    for index, row in df.iterrows():
        # Extract month and year from the MONTH column
        date = datetime.strptime(row['MONTH'], "%Y-%m-%d")
        month = date.month
        year = date.year
        schema = f"{year}_{str(month).zfill(2)}"

        # Extract other values
        if pd.isna(row['POLYGON_L8']):
            continue
        polygon = row['POLYGON_L8']
        mobility_type = row['MOBILITY_TYPE'] if pd.notna(row['MOBILITY_TYPE']) else 'PASSERBY'
        user_reach = row['USER_REACH'] if pd.notna(row['USER_REACH']) else 0

        # Initialize dictionary entry if it doesn't exist
        if (polygon) not in mobility_data:
            mobility_data[(polygon)] = {
                'date': date.strftime('%Y-%m-%d'),
                'home_user_reach': 0,
                'work_user_reach': 0,
                'passerby_user_reach': 0,
            }

        # Aggregate the user reach based on mobility type
        if mobility_type == 'HOME':
            mobility_data[(polygon)]['home_user_reach'] = user_reach
        elif mobility_type == 'WORK':
            mobility_data[(polygon)]['work_user_reach'] = user_reach
        else:
            mobility_data[(polygon)]['passerby_user_reach'] = user_reach

    # Create the VALUES part of the SQL query
    values_list = []
    for (polygon), data in mobility_data.items():
        values_list.append((
            data['date'], polygon, 
            data['home_user_reach'], data['work_user_reach'], data['passerby_user_reach']
        ))

    values_part = ',\n'.join(
        f"('{date}', '{polygon}', {home_user_reach}, {work_user_reach}, {passerby_user_reach})"
        for date, polygon, home_user_reach, work_user_reach, passerby_user_reach in values_list
    )

    # Create the upsert query
    query = f"""
    SELECT create_schema_and_tables('{schema}');
    INSERT INTO "{schema}".mobility_type_wise_user_reaches (date, polygon, home_user_reach, work_user_reach, passerby_user_reach)
    VALUES {values_part}
    ON CONFLICT (polygon) DO UPDATE SET
        home_user_reach = EXCLUDED.home_user_reach,
        work_user_reach = EXCLUDED.work_user_reach,
        passerby_user_reach = EXCLUDED.passerby_user_reach;
    """

    return query


def process_avg_work_distance(df):
    # Initialize a dictionary to store the avg_work_distance for each polygon
    work_distance_data = {}

    for index, row in df.iterrows():
        # Extract month and year from the MONTH column
        date = datetime.strptime(row['MONTH'], "%Y-%m-%d")
        month = date.month
        year = date.year
        schema = f"{year}_{str(month).zfill(2)}"

        # Extract other values
        if pd.isna(row['POLYGON_L8']):
            continue
        polygon = row['POLYGON_L8']
        avg_work_distance = row['AVG_WORK_DISTANCE'] if pd.notna(row['AVG_WORK_DISTANCE']) else None

        # Skip rows with missing avg_work_distance
        if avg_work_distance is not None:
            # Store the average work distance for each polygon
            work_distance_data[(polygon)] = {
                'date': date.strftime('%Y-%m-%d'),
                'avg_work_distance': avg_work_distance
            }

    # Create the VALUES part of the SQL query
    values_list = []
    for (polygon), data in work_distance_data.items():
        values_list.append((
            data['date'], polygon, 
            data['avg_work_distance']
        ))

    values_part = ',\n'.join(
        f"('{date}', '{polygon}', {avg_work_distance})"
        for date, polygon, avg_work_distance in values_list
    )

    # Create the upsert query
    query = f"""
    SELECT create_schema_and_tables('{schema}');
    INSERT INTO "{schema}".mobility_type_wise_user_reaches (date, polygon, avg_work_distance)
    VALUES {values_part}
    ON CONFLICT (polygon) DO UPDATE SET
        avg_work_distance = EXCLUDED.avg_work_distance;
    """

    return query


def process_avg_home_distance(df):
    # Initialize a dictionary to store the avg_home_distance for each polygon
    home_distance_data = {}

    for index, row in df.iterrows():
        # Extract month and year from the MONTH column
        date = datetime.strptime(row['MONTH'], "%Y-%m-%d")
        month = date.month
        year = date.year
        schema = f"{year}_{str(month).zfill(2)}"

        # Extract other values
        if pd.isna(row['POLYGON_L8']):
            continue
        polygon = row['POLYGON_L8']
        avg_home_distance = row['AVG_HOME_DISTANCE'] if pd.notna(row['AVG_HOME_DISTANCE']) else None

        # Skip rows with missing avg_home_distance
        if avg_home_distance is not None:
            # Store the average home distance for each polygon
            home_distance_data[(polygon)] = {
                'date': date.strftime('%Y-%m-%d'),
                'avg_home_distance': avg_home_distance
            }

    # Create the VALUES part of the SQL query
    values_list = []
    for (polygon), data in home_distance_data.items():
        values_list.append((
            data['date'], polygon, 
            data['avg_home_distance']
        ))

    values_part = ',\n'.join(
        f"('{date}', '{polygon}', {avg_home_distance})"
        for date, polygon, avg_home_distance in values_list
    )
    
    # Create the upsert query
    query = f"""
    SELECT create_schema_and_tables('{schema}');
    INSERT INTO "{schema}".mobility_type_wise_user_reaches (date, polygon, avg_home_distance)
    VALUES {values_part}
    ON CONFLICT (polygon) DO UPDATE SET
        avg_home_distance = EXCLUDED.avg_home_distance;
    """
    
    return query


def process_home_reach_monthly(df):
    # Initialize a list to store values for bulk insertion
    values_list = []

    for index, row in df.iterrows():
        # Extract month and year from the MONTH column
        date = datetime.strptime(row['MONTH'], "%Y-%m-%d")
        month = date.month
        year = date.year
        schema = f"{year}_{str(month).zfill(2)}"

        # Extract other values
        if pd.isna(row['POLYGON_L8']):
            continue
        polygon = row['POLYGON_L8']
        state = row['HOME_STATE'] if pd.notna(row['HOME_STATE']) else ''
        user_reach = row['USER_REACH'] if pd.notna(row['USER_REACH']) else 0

        # Add a row for the data
        values_list.append((
            date.strftime('%Y-%m-%d'), polygon, 
            'HOME', user_reach, state
        ))

    # Create the VALUES part of the SQL query
    values_part = ',\n'.join(
        f"('{date}', '{polygon}', '{mobility_type}', {user_reach}, '{state}')"
        for date, polygon, mobility_type, user_reach, state in values_list
    )

    # Create the upsert query
    query = f"""
    SELECT create_schema_and_tables('{schema}');
    INSERT INTO "{schema}".mobility_state_wise_user_reaches (date, polygon, mobility_type, user_reach, state)
    VALUES {values_part}
    ON CONFLICT (polygon, mobility_type, state) DO NOTHING;
    """

    return query


def process_work_reach_monthly(df):
    # Initialize a list to store values for bulk insertion
    values_list = []

    for index, row in df.iterrows():
        # Extract month and year from the MONTH column
        date = datetime.strptime(row['MONTH'], "%Y-%m-%d")
        month = date.month
        year = date.year
        schema = f"{year}_{str(month).zfill(2)}"

        # Extract other values
        if pd.isna(row['POLYGON_L8']):
            continue
        polygon = row['POLYGON_L8']
        state = row['WORK_STATE'] if pd.notna(row['WORK_STATE']) else ''
        user_reach = row['USER_REACH'] if pd.notna(row['USER_REACH']) else 0

        # Add a row for the data
        values_list.append((
            date.strftime('%Y-%m-%d'), polygon, 
            'WORK', user_reach, state
        ))

    # Create the VALUES part of the SQL query
    values_part = ',\n'.join(
        f"('{date}', '{polygon}', '{mobility_type}', {user_reach}, '{state}')"
        for date, polygon, mobility_type, user_reach, state in values_list
    )

    # Create the upsert query
    query = f"""
    SELECT create_schema_and_tables('{schema}');
    INSERT INTO "{schema}".mobility_state_wise_user_reaches (date, polygon, mobility_type, user_reach, state)
    VALUES {values_part}
    ON CONFLICT (polygon, mobility_type, state) DO NOTHING;
    """

    return query


def process_reach_hourly(df):
    # Initialize a list to store values for bulk insertion
    values_list = []

    for index, row in df.iterrows():
        # Extract date, month, and year from the date column
        date = datetime.strptime(row['MONTH'], "%Y-%m-%d")
        month = date.month
        year = date.year
        schema = f"{year}_{str(month).zfill(2)}"

        # Extract other values
        weekday = row['DAY'] if pd.notna(row['DAY']) else ''
        hour = row['HOUR'] if pd.notna(row['HOUR']) else 0
        if pd.isna(row['POLYGON_L8']):
            continue
        polygon = row['POLYGON_L8']
        impressions = row['IMPRESSIONS'] if pd.notna(row['IMPRESSIONS']) else 0
        user_reach = row['USER_REACH'] if pd.notna(row['USER_REACH']) else 0
        daily_avg_impressions = row['DAILY_AVERAGE_IMPRESSIONS'] if pd.notna(row['DAILY_AVERAGE_IMPRESSIONS']) else 0
        daily_avg_user_reach = row['DAILY_AVERAGE_USER_REACH'] if pd.notna(row['DAILY_AVERAGE_USER_REACH']) else 0

        # Add a row for the data
        values_list.append((
            date.strftime('%Y-%m-%d'),  polygon, weekday, hour, 
            impressions, user_reach, daily_avg_impressions, daily_avg_user_reach
        ))

    # Create the VALUES part of the SQL query
    values_part = ',\n'.join(
        f"('{date}',  '{polygon}', '{weekday}', {hour}, {impressions}, {user_reach}, {daily_avg_impressions}, {daily_avg_user_reach})"
        for date,  polygon, weekday, hour, impressions, user_reach, daily_avg_impressions, daily_avg_user_reach in values_list
    )

    # Create the upsert query
    query = f"""
    SELECT create_schema_and_tables('{schema}');
    INSERT INTO "{schema}".hourly_trends (
        date, polygon, weekday, hour, impressions, user_reach, 
        daily_average_impressions, daily_average_user_reach
    )
    VALUES {values_part}
    ON CONFLICT (polygon, weekday, hour) DO NOTHING;
    """

    return query

def process_reach_days(df):
    # Initialize a list to store values for bulk insertion
    values_list = []

    for index, row in df.iterrows():
        # Extract date, month, and year from the date column
        date = datetime.strptime(row['DATA_DATE'], "%Y-%m-%d")
        month = date.month
        year = date.year
        schema = f"{year}_{str(month).zfill(2)}"
        date_string = date.strftime('%Y-%m-%d')

        # Extract other values
        weekday = row['DAY'] if pd.notna(row['DAY']) else ''

        if pd.isna(row['POLYGON_L8']):
            continue
        polygon = row['POLYGON_L8']
        impressions = row['IMPRESSIONS'] if pd.notna(row['IMPRESSIONS']) else 0
        user_reach = row['USER_REACH'] if pd.notna(row['USER_REACH']) else 0

        # Add a row for the data
        values_list.append((
            date_string, polygon, weekday, impressions, user_reach
        ))

    # Create the VALUES part of the SQL query
    values_part = ',\n'.join(
        f"('{date}',  '{polygon}', '{weekday}', {impressions}, {user_reach})"
        for date,  polygon, weekday, impressions, user_reach in values_list
    )

    # Create the upsert query
    query = f"""
    SELECT create_schema_and_tables('{schema}');
    INSERT INTO "{schema}".daily_trends (
        date, polygon, weekday, impressions, user_reach
    )
    VALUES {values_part}
    ON CONFLICT (polygon, date) DO NOTHING;
    """

    return query
