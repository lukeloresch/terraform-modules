//assumes vpc/subnets are already created

#################### 
#ROLES
#################### 
resource "aws_iam_role" "apps-node" {
  name = "terraform-eks-${var.cluster_name}-cluster"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "apps-cluster-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = "${aws_iam_role.apps-node.name}"
}

resource "aws_iam_role_policy_attachment" "apps-cluster-AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = "${aws_iam_role.apps-node.name}"
}

#################### 
# Security Groups
#################### 
resource "aws_security_group" "apps-cluster" {
  name        = "terraform-eks-apps-cluster"
  description = "Cluster communication with worker nodes"
  vpc_id      = "${var.vpc_id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "terraform-eks-apps"
  }
}

# OPTIONAL: Allow inbound traffic from your local workstation external IP
#           to the Kubernetes. You will need to replace A.B.C.D below with
#           your real IP. Services like icanhazip.com can help you find this.
resource "aws_security_group_rule" "apps-cluster-ingress-workstation-https" {
  cidr_blocks       = ["A.B.C.D/32"]
  description       = "Allow workstation to communicate with the cluster API Server"
  from_port         = 443
  protocol          = "tcp"
  security_group_id = "${aws_security_group.apps-cluster.id}"
  to_port           = 443
  type              = "ingress"
}

#################### 
# Cluster
#################### 

resource "aws_eks_cluster" "apps" {
  name            = "${var.cluster-name}"
  role_arn        = "${aws_iam_role.apps-node.arn}"

  vpc_config {
    security_group_ids = ["${aws_security_group.apps-cluster.id}"]
    subnet_ids         = ["${aws_subnet.apps.*.id}"]
  }

  depends_on = [
    "aws_iam_role_policy_attachment.apps-cluster-AmazonEKSClusterPolicy",
    "aws_iam_role_policy_attachment.apps-cluster-AmazonEKSServicePolicy",
  ]
}
