resource "aws_iam_openid_connect_provider" "github_provider" {
  client_id_list  = ["https://github.com/${var.github_organization}", "sts.amazonaws.com"]
  thumbprint_list = var.github_thumbprint_list
  url             = "https://token.actions.githubusercontent.com"
  tags            = var.tags
}

data "aws_iam_policy_document" "github_assume_role" {
  for_each = var.github_repository_role

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"
    condition {
      test     = "StringLike"
      values   = ["repo:${var.github_organization}/${each.value.repository}:*"]
      variable = "token.actions.githubusercontent.com:sub"
    }
    principals {
      identifiers = [aws_iam_openid_connect_provider.github_provider.arn]
      type        = "Federated"
    }
  }
  version = "2012-10-17"
}

resource "aws_iam_role" "github_role" {
  for_each = var.github_repository_role

  name                 = each.value.iam_role_name
  description          = "Role used by the ${var.github_organization} GitHub organization limited to the ${each.value.repository} repository"
  max_session_duration = 3600
  path                 = each.value.iam_path
  assume_role_policy   = data.aws_iam_policy_document.github_assume_role[each.key].json
  tags                 = var.tags
}

data "aws_iam_policy_document" "github_role_policy_document" {
  for_each = var.github_repository_role

  source_policy_documents = each.value.iam_source_policy_documents
}

resource "aws_iam_policy" "github_role_policy" {
  for_each = var.github_repository_role

  name        = "${each.value.iam_role_name}-policy"
  description = "Dynamic policy used by ${each.value.iam_role_name} (${var.github_organization}/${each.value.repository})"
  path        = each.value.iam_path
  policy      = data.aws_iam_policy_document.github_role_policy_document[each.key].json
  tags        = var.tags
}

resource "aws_iam_role_policy_attachment" "github_role_policy_attachment" {
  for_each = var.github_repository_role

  policy_arn = aws_iam_policy.github_role_policy[each.key].arn
  role       = aws_iam_role.github_role[each.key].id
}
