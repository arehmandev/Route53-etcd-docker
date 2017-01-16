module "route53" {
  source       = "github.com/arehmandev/Prototype-X/modules/route53"
  depends-on   = "${module.vpc.dependency}"
  internal-tld = "${var.internal-tld}"
  vpcid        = "${module.vpc.aws_vpc.id}"
  cluster-name = "${var.cluster-name}"
}

variable "depends-on" {
  default = "${module.yourvpc.dependencyoutput}"
}

variable "internal-tld" {
  default = "testinternal.com"
}

variable "vpcid" {
  default = "${module.yourvpc.idoutput}"
}

variable "cluster-name" {
  default = "yourclustername"
}
