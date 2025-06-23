variable "usernames" {
  type    = list(string)
  default = ["sita", "raadha", "padma"]
}

# IAM Users
resource "aws_iam_user" "users" {
  for_each = toset(var.usernames)
  name     = each.key
}

# IAM Access Keys
resource "aws_iam_access_key" "keys" {
  for_each = aws_iam_user.users
  user     = each.value.name
}

# IAM Login Profiles (optional - if users have console passwords)
resource "aws_iam_user_login_profile" "login_profiles" {
  for_each = aws_iam_user.users
  user     = each.value.name
  pgp_key  = "keybase:some-key" # Or omit if not used
}

# IAM Group Memberships
resource "aws_iam_user_group_membership" "group_membership" {
  for_each = aws_iam_user.users
  user     = each.value.name
  groups   = ["example-group"] # Replace with real group if needed
}

# IAM Policy Attachments (optional)
resource "aws_iam_user_policy_attachment" "policy_attachment" {
  for_each   = aws_iam_user.users
  user       = each.value.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess" # Replace as needed
}

# Cleanup null resource to ensure order of destruction
resource "null_resource" "cleanup" {
  depends_on = [
    aws_iam_access_key.keys,
    aws_iam_user_login_profile.login_profiles,
    aws_iam_user_group_membership.group_membership,
    aws_iam_user_policy_attachment.policy_attachment,
  ]
}

# Mark users for deletion only after cleanup
resource "aws_iam_user" "users_destroyable" {
  for_each = aws_iam_user.users
  name     = each.value.name

  lifecycle {
    prevent_destroy = false
  }

  depends_on = [null_resource.cleanup]
}
