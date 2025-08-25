import os
import json
import zipfile
import tempfile
import datetime
import psutil
import time
from ftplib import FTP
from time import sleep

start_time = time.time()

if not os.path.exists('backup_config.json'):
    print('No backup config file found')
    print('Creating backup config file')
    default_config = {
        "FTP_SERVER": "u438584-sub.your-storagebox.de",
        "FTP_USER": "u438584-sub",
        "FTP_PASS": "password",
        "BACKUP_PATH": "/",
        "SOURCE_DIRS": ["C:\\PC-CASH twin HP", "C:\\PC-CASH twin"],
        "MAX_SIZE": "10GB",
        "TIMEOUT_SECONDS": 7200,
        "UPLOAD_MAX_RETRIES": 3,
        "LOG_PATH": "C:\\BackupLogs\\backup.log"
    }
    with open('backup_config.json', 'w', encoding='utf-8') as f:
        json.dump(default_config, f, indent=4, ensure_ascii=False)
    print('Created backup config file')
    exit(1)

with open('backup_config.json', 'r', encoding='utf-8') as f:
    config = json.load(f)

source_dirs = config['SOURCE_DIRS']
folder_names = "_".join([os.path.basename(d.strip('\\/')) for d in source_dirs])
timestamp = datetime.datetime.now().strftime('%Y%m%d_%H%M%S')
zip_filename = os.path.join(tempfile.gettempdir(), f'backup_{timestamp}.zip')

ftp_server = config['FTP_SERVER']
ftp_user = config['FTP_USER']
ftp_pass = config['FTP_PASS']
backup_path = config['BACKUP_PATH']
max_size = config['MAX_SIZE']
timeout_seconds = config['TIMEOUT_SECONDS']
upload_max_retries = config['UPLOAD_MAX_RETRIES']
log_path = config['LOG_PATH']

os.makedirs(os.path.dirname(log_path), exist_ok=True)


def log(message):
    with open(log_path, 'a', encoding='utf-8') as log_file:
        formatted = f"{datetime.datetime.now().isoformat()} - {message}\n"
        log_file.write(formatted)
        print(formatted)


log(f"FTP_SERVER: {ftp_server}")
log(f"FTP_USER: {ftp_user}")
log(f"FTP_PASS: {ftp_pass}")
log(f"BACKUP_PATH: {backup_path}")
log(f"SOURCE_DIRS: {source_dirs}")
log(f"MAX_SIZE: {max_size}")
log(f"TIMEOUT_SECONDS: {timeout_seconds}")
log(f"UPLOAD_MAX_RETRIES: {upload_max_retries}")
log(f"LOG_PATH: {log_path}")

unit = max_size[-2:].upper()

if unit == 'GB':
    max_size_bytes = int(max_size[:-2]) * 1024 ** 3
elif unit == 'MB':
    max_size_bytes = int(max_size[:-2]) * 1024 ** 2
elif unit == 'KB':
    max_size_bytes = int(max_size[:-2]) * 1024
else:
    log(f"Unsupported unit '{unit}' in MAX_SIZE: {max_size}. Supported units are GB, MB, KB.")
    if os.path.exists(zip_filename):
        os.remove(zip_filename)
    raise ValueError(f"Unit '{unit}' is not supported.")

log(f"Connecting to FTP server '{ftp_server}' with user '{ftp_user}'...")
try:
    ftp = FTP(ftp_server)
    ftp.set_pasv(True)
    ftp.login(user=ftp_user, passwd=ftp_pass)
except Exception as e:
    log(f"Failed to connect to FTP server '{ftp_server}' with user '{ftp_user}': {e}")
    os.remove(zip_filename)
    raise ConnectionError(f"Could not connect to FTP server: {e}")
log("Connected to FTP server.")

process_names = ['twin.exe', 'elerechnung.exe']
for proc in psutil.process_iter(['name']):
    if proc.info['name'] in process_names:
        log(f"Kill process: {proc.info['name']} (PID: {proc.pid})")
        proc.terminate()
        try:
            proc.wait(timeout=10)
            log(f"Process terminated: {proc.info['name']}")
        except psutil.TimeoutExpired:
            log(f"Process {proc.info['name']} (PID: {proc.pid}) could not be terminated within 10 seconds.")

for d in source_dirs[:]:
    if not os.path.exists(d):
        log("Source directory does not exist: " + d)
        source_dirs.remove(d)

if source_dirs == []:
    log("No valid source directories found. Exiting. in 10 seconds.")
    if os.path.exists(zip_filename):
        os.remove(zip_filename)
    if ftp:
        ftp.quit()
    sleep(10)
    exit(1)

total_files = sum(len(files) for d in source_dirs if os.path.exists(d) for _, _, files in os.walk(d))

processed_files = 0


def check_timeout():
    elapsed = time.time() - start_time
    if elapsed > timeout_seconds:
        log(f"Script timeout exceeded ({timeout_seconds} seconds). Exiting.")
        if ftp:
            try:
                ftp.delete(f"backup_{timestamp}.zip")
                ftp.close()
                ftp.quit()
            except Exception as e:
                log(f"Error during FTP cleanup: {e}")
        if os.path.exists(zip_filename):
            try:
                zipf.close()
                os.remove(zip_filename)
            except OSError as e:
                log(f"Could not remove temporary ZIP file '{zip_filename}': {e}")
        raise TimeoutError(f"Script execution exceeded the timeout of {timeout_seconds} seconds.")


check_timeout()

with zipfile.ZipFile(zip_filename, 'w', zipfile.ZIP_DEFLATED) as zipf:
    for source_dir in source_dirs:
        if not os.path.exists(source_dir):
            log(f"Source directory '{source_dir}' does not exist. Skipping.")
            continue
        for root, dirs, files in os.walk(source_dir):
            for file in files:
                file_path = os.path.join(root, file)
                if os.path.isfile(file_path):
                    try:
                        os.rename(file_path, file_path)
                    except OSError as e:
                        log(f"File '{file}' could not be added to the ZIP file: {e}")
                        continue
                arcname = os.path.relpath(file_path, start=source_dir)
                arcname = os.path.join(os.path.basename(source_dir.strip('\\/')), arcname)
                zipf.write(file_path, arcname)

                processed_files += 1
                check_timeout()
                print(f"Progress: {processed_files}/{total_files} files added to ZIP.")
log(f"ZIP-File '{zip_filename}' was created.")

zip_file_size = os.path.getsize(zip_filename)
log(f"ZIP-File size: {zip_file_size} bytes.")

if zip_file_size > max_size_bytes:
    os.remove(zip_filename)
    raise ValueError(
        f"The ZIP file '{zip_filename}' is too large ({zip_file_size} Bytes). Maximum allowed: {max_size_bytes} Bytes.")

log("FTP Server root size check...")
ftp.cwd(backup_path)
root_size = 0
for entry in ftp.mlsd():
    name, facts = entry
    if facts.get('type') == 'file':
        check_timeout()
        root_size += int(facts.get('size', 0))

log(f"Root directory size on FTP server: {root_size} bytes")

if root_size + zip_file_size > max_size_bytes:
    log(f"The size of the root directory on the FTP server ({root_size} Bytes) plus the ZIP file ({zip_file_size} Bytes) exceeds the limit of {max_size_bytes} Bytes.")
    files = sorted(ftp.mlsd(), key=lambda x: x[1].get('modify', ''))
    for name, facts in files:
        if facts.get('type') == 'file':
            file_size = int(facts.get('size', 0))
            if root_size + zip_file_size <= max_size_bytes:
                break
            log(f"Deleting file '{name}' from FTP server...")
            ftp.delete(name)
            root_size -= file_size
    log(f"After deletion, the size of the root directory on the FTP server is: {root_size} Bytes")
else:
    log(f"The size of the root directory on the FTP server is within the limit of {max_size_bytes} Bytes.")

check_timeout()
log(f"Uploading ZIP file '{zip_filename}' to FTP server...")
upload_success = False
for attempt in range(1, upload_max_retries + 1):
    try:
        with open(zip_filename, 'rb') as f:
            ftp.storbinary(f'STOR backup_{timestamp}.zip', f, callback=lambda x: check_timeout())
        upload_success = True
        log(f"Upload successful on attempt {attempt}")
        break
    except Exception as e:
        log(f"Upload attempt {attempt}/{upload_max_retries} failed: {e}")
        if attempt < upload_max_retries:
            log("Retrying upload in 5 seconds...")
            time.sleep(5)

if upload_success:
    log(f"Backup completed successfully at {datetime.datetime.now().isoformat()}.")
else:
    log(f"Failed to upload backup after {upload_max_retries} attempts.")
    log(Exception(f"Failed to upload backup after {upload_max_retries} attempts."))

log(f"Removing temporary ZIP file '{zip_filename}'...")
os.remove(zip_filename)
ftp.quit()

log(f"Backup script completed in {time.time() - start_time:.2f} seconds.")

restartIn = 30  # seconds
log(f"Backup completed successfully. Restarting the computer in {restartIn} seconds...")
os.system(f"shutdown /r /t {restartIn}")
