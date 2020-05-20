# pylint: disable=missing-docstring, line-too-long, protected-access, E1101, C0202, E0602, W0109
# import relevant modules
import unittest
from runner import Runner

# Creates a class derived form unittest.TestCase

class TestE2E(unittest.TestCase):
    @classmethod
    def setUpClass(self):
        self.snippet = """
            provider "aws" {
              region = "eu-west-2"
             #profile = "foo"
              skip_credentials_validation = true
              skip_get_ec2_platforms = true
            }

            module "dailytasks" {
              source = "./mymodule"
             # providers = {aws = "aws"}

              path_module = "./"
              namespace     = "test"
              naming_suffix = "test-dq"
            }
        """
        self.result = Runner(self.snippet).result

    def test_root_destroy(self):
        self.assertEqual(self.result["destroy"], False)

    def test_name_suffix_aws_lambda_function_rdsshutdown_tags(self):
        self.assertEqual(self.result['dailytasks']["aws_lambda_function.rds-shutdown-function"]["tags.Name"], "rds-shutdown-test-dq")

    def test_name_suffix_aws_iam_role_rds_shutdown_role_tags(self):
          self.assertEqual(self.result['dailytasks']["aws_iam_role.rds-shutdown-role"]["tags.Name"], "rds-shutdown-role-test-dq")

    def test_name_suffix_aws_lambda_function_ec2_shutdown_tags(self):
            self.assertEqual(self.result['dailytasks']["aws_lambda_function.ec2_shutdown"]["tags.Name"], "ec2-shutdown-notprod-dq")

    def test_name_suffix_aws_iam_role_ec2_shutdown_role_tags(self):
            self.assertEqual(self.result['dailytasks']["aws_iam_role.ec2_shutdown"]["tags.Name"], "ec2-shutdown-notprod-dq")

if __name__ == '__main__':
    unittest.main()
