resource "aws_security_group" "maskopy_app" {
  provider = aws.staging
  count    = var.enabled ? 1 : 0

  name        = "MASKOPY-app"
  description = "Security group for Maskopy app"
  vpc_id      = var.staging_vpc_id

  tags = {
    Tool = "maskopy"
  }
}

resource "aws_security_group" "maskopy_db" {
  provider = aws.staging
  count    = var.enabled ? 1 : 0

  name        = "MASKOPY-db"
  description = "Security group for Maskopy db"
  vpc_id      = var.staging_vpc_id

  tags = {
    Tool = "maskopy"
  }
}

resource "aws_security_group_rule" "outbound_rule_00" {
  provider = aws.staging
  count    = var.enabled ? 1 : 0

  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.maskopy_app[0].id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "outbound_rule_01" {
  provider = aws.staging
  count    = var.enabled ? 1 : 0

  type                     = "egress"
  from_port                = 2484
  to_port                  = 2484
  protocol                 = "tcp"
  security_group_id        = aws_security_group.maskopy_app[0].id
  source_security_group_id = aws_security_group.maskopy_db[0].id
}

resource "aws_security_group_rule" "outbound_rule_02" {
  provider = aws.staging
  count    = var.enabled ? 1 : 0

  type                     = "egress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.maskopy_app[0].id
  source_security_group_id = aws_security_group.maskopy_db[0].id
}

resource "aws_security_group_rule" "inbound_rule_00" {
  provider = aws.staging
  count    = var.enabled ? 1 : 0

  type                     = "ingress"
  from_port                = 2484
  to_port                  = 2484
  protocol                 = "tcp"
  security_group_id        = aws_security_group.maskopy_db[0].id
  source_security_group_id = aws_security_group.maskopy_app[0].id
}

resource "aws_security_group_rule" "inbound_rule_01" {
  provider = aws.staging
  count    = var.enabled ? 1 : 0

  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.maskopy_db[0].id
  source_security_group_id = aws_security_group.maskopy_app[0].id
}
