resource "aws_service_discovery_private_dns_namespace" "main" {
  name        = "${var.project_name}.local"
  vpc         = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-namespace"
  }
}

resource "aws_service_discovery_service" "main" {
  name = "${var.project_name}-service"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.main.id

    dns_records {
      ttl  = 60
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}

resource "aws_service_discovery_instance" "ap_1a" {
  instance_id = "ap_1a"
  service_id  = aws_service_discovery_service.main.id

  attributes = {
    AWS_INSTANCE_IPV4 = aws_instance.ap_server_1a.private_ip
    AWS_INSTANCE_PORT = "80"
  }
}

resource "aws_service_discovery_instance" "ap_1c" {
  instance_id = "ap_1c"
  service_id  = aws_service_discovery_service.main.id

  attributes = {
    AWS_INSTANCE_IPV4 = aws_instance.ap_server_1c.private_ip
    AWS_INSTANCE_PORT = "80"
  }
}