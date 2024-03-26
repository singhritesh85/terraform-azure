#############################################################################
prefix = "aks"
location = ["East US", "East US 2", "Central India", "Central US"]
kubernetes_version = ["1.26.6", "1.26.10", "1.27.3", "1.27.7", "1.28.0", "1.28.3", "1.28.5", "1.29.0", "1.29.2"]
ssh_public_key = "ssh-key"
action_group_shortname = "aks-action"
env = ["dev", "stage", "prod"]
