#################################### Variables for Azure Storage Account to be created ################################################

prefix = "mesco"
location = ["East US", "East US 2", "Central India", "Central US"]
account_tier = ["Standard", "Premium"]    ### For BlockBlobStorage and FileStorage accounts only Premium is valid option.
account_replication_type = ["LRS", "GRS", "RAGRS", "ZRS", "GZRS", "RAGZRS"]
env = ["dev", "stage", "prod"]
min_tls_version = ["TLS1_0", "TLS1_1", "TLS1_2"]
access_tier = ["Hot", "Cold"]
routing_choice =["InternetRouting", "MicrosoftRouting"]
container_delete_retaintion = 7
blob_delete_retaintion = 7
