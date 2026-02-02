#!/usr/bin/env ruby

require 'aws-sdk-s3'
require 'dotenv/load'

puts "🛠️ Configuration du CORS sur le bucket S3..."

client = Aws::S3::Client.new(
  region: ENV.fetch('AWS_REGION', 'eu-west-1'),
  access_key_id: ENV.fetch('BUCKETEER_AWS_ACCESS_KEY_ID'),
  secret_access_key: ENV.fetch('BUCKETEER_AWS_SECRET_ACCESS_KEY')
)

bucket = ENV.fetch('BUCKETEER_BUCKET_NAME')

client.put_bucket_cors({
  bucket: bucket,
  cors_configuration: {
    cors_rules: [
      {
        allowed_headers: ['*'],
        allowed_methods: ['GET', 'PUT', 'POST'],
        allowed_origins: [
          "https://www.coopcom.fr",
          "https://coopcom-a2c1f0a1f936.herokuapp.com",
          "http://localhost:3000",
          "http://127.0.0.1:3000"
        ],
        expose_headers: ['ETag'],
        max_age_seconds: 3000
      }
    ]
  }
})

puts "✅ CORS configuré avec succès sur le bucket #{bucket}"