resource "aws_dynamodb_table" "Telemetry-dynamodb-table" {
  name           = "TemperatureData"
  hash_key       = "time"
  billing_mode = "PROVISIONED"
  write_capacity = 1
  read_capacity = 1

  attribute {
    name = "time"
    type = "S"
  }
}