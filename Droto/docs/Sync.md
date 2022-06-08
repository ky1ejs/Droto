# Sync Jobs

## Folder Syncing 

1. Get list of folders should be syncing
2. Get the current contents of each folder
3. Get the current local synced files that claim to be in that folder id
4. Keep any photos that exist from 3 in 2
5. Delete any that don't exist
6. Download any new ones

## Syncing one off files

1. List syned of files
2. Call the file id in Google drive
3. With the file data returned from Drive:
```
  start
  |
  |_________ doesn't exist _____ delete from device
  |
  |_________ isTrashed == true  _____ delete from device
  |
  |_________ md5Checksum !== storedChecksum  _____ update image on device
  |
  |_________ do nothing
```

```
{
  "users_data": {
    "1234_user_id": {
      "synced_folders": {
        "google_folder_id": { 
          "google_drive_file_id": {
            "photosId": "1234",
            "photosCloudId": "1234",
            "googleDriveMd5Checksum": "1234"
          }
          ...
        }
        ...
      }
    }
  }
}
```
