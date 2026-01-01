module "b2" {
  source = "./b2"

  b2          = var.b2
  bucket_name = var.bucket_name
}
