module "test_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 3.0"

  name = "${var.name_prefix}-test"

  ami           = "ami-0416b2a68b612a602" # ubuntu
  instance_type = "t4g.micro"

  key_name                    = var.ssh_key_name
  monitoring                  = true
  associate_public_ip_address = true
  availability_zone           = element(module.vpc.azs, 0)
  subnet_id                   = element(module.vpc.public_subnets, 0)
  vpc_security_group_ids      = [module.security_group.security_group_id]

  ebs_optimized = true
}

resource "null_resource" "test_instance" {
  # To ensure that it runs always
  triggers = {
    instance_ids = module.test_instance.id
    always_run   = "${timestamp()}"
  }

  # Running the remote provisioner like this ensures that ssh is up and running,
  # and install python dependency before running the local provisioner
  provisioner "remote-exec" {
    inline = ["echo Hello World", "sudo apt-get install python3 -y"]
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file(var.private_key_path)
    host        = module.test_instance.public_ip
  }

  # Create the inventory file needed for Ansible
  provisioner "local-exec" {
    command = "echo '${module.test_instance.id} ansible_host=${module.test_instance.public_ip} ansible_ssh_user=ubuntu ansible_python_interpreter=/usr/bin/python3' > ./ansible/inventory"
  }

  # Execute the Ansible playbook
  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook ./ansible/playbook.yaml -i ./ansible/inventory --private-key ${var.private_key_path}"
  }
}
