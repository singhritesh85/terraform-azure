#############################################################################
prefix = "aks"
location = ["East US", "East US 2", "Central India", "Central US"]
kubernetes_version = ["1.26.6", "1.26.10", "1.27.3", "1.27.7", "1.28.0", "1.28.3", "1.28.5", "1.29.0", "1.29.2"]
ssh_public_key = "ssh-key"
action_group_shortname = "aks-action"
account_tier = ["Standard", "Premium"]    ### For BlockBlobStorage and FileStorage accounts only Premium is valid option.
account_replication_type = ["LRS", "GRS", "RAGRS", "ZRS", "GZRS", "RAGZRS"]
min_tls_version = ["TLS1_0", "TLS1_1", "TLS1_2"]
container_name = "nokoyaza-project"
container_access_type = ["blob", "private"]   ### container or private both are same. Default value is private.
access_tier = ["Hot", "Cold"]
routing_choice =["InternetRouting", "MicrosoftRouting"]
container_delete_retaintion = 7
blob_delete_retaintion = 7
env = ["dev", "stage", "prod"]
