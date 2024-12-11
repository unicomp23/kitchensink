module "single_lambda" {
  source                 = "../modules/lambda"
  bucket_name            = "kafka-poc-results" # Replace with your bucket name
  lambda_name            = "AnalyticsLambda"
  memory_size            = 10240 # 10 GB of memory 
  timeout                = 900   # 15 minutes timeout
  ephemeral_storage_size = 10240 # 10 GB ephemeral storage
  pandas_layer_arn       = "arn:aws:lambda:us-east-1:060795946368:layer:pandas-layer-python313:2"
}
