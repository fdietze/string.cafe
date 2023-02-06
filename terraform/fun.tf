locals {
  is_prod = terraform.workspace == "default"

  name_prefix = "string-cafe-${terraform.workspace}"
}

module "string_cafe" {
  source  = "fun-stack/fun/aws"
  version = "0.11.14"

  stage = terraform.workspace
  name_prefix = local.name_prefix

  domain = {
    name                = "string.cafe"
    deploy_to_subdomain = local.is_prod ? null : "${terraform.workspace}.env"
    catch_all_email     = "string.cafe@felx.me"
  }

  website = {
    source_dir              = "../webapp/target/scala-2.13/scalajs-bundler/main/dist"
    cache_files_regex       = ".*-hashed.(js|css)"
    # content_security_policy = "default-src 'self'; connect-src https://* wss://*; frame-ancestors 'none'; frame-src 'none';"
    rewrites = {
      "robots.txt" = "robots.deny.txt" # local.is_prod ? "robots.allow.txt" : "robots.deny.txt"
    }
  }

  http = {
    api = {
      source_dir  = "../lambda/target/scala-2.13/scalajs-bundler/main/dist"
      handler     = "main.httpApi"
      runtime     = "nodejs14.x"
      memory_size = 256
      environment = {
        NODE_OPTIONS = "--enable-source-maps"
      }
    }

    rpc = {
      source_dir  = "../lambda/target/scala-2.13/scalajs-bundler/main/dist"
      handler     = "main.httpRpc"
      runtime     = "nodejs14.x"
      memory_size = 256
      environment = {
        NODE_OPTIONS = "--enable-source-maps"

        SNS_CHIME_TOPIC_ARN = aws_sns_topic.meeting_events.arn
      }
    }
  }

  ws = {
    rpc = {
      source_dir  = "../lambda/target/scala-2.13/scalajs-bundler/main/dist"
      handler     = "main.wsRpc"
      runtime     = "nodejs14.x"
      memory_size = 256
      environment = {
        NODE_OPTIONS = "--enable-source-maps"
      }
    }

    event_authorizer = {
      source_dir  = "../lambda/target/scala-2.13/scalajs-bundler/main/dist"
      handler     = "main.wsEventAuth"
      runtime     = "nodejs14.x"
      memory_size = 256
      environment = {
        NODE_OPTIONS = "--enable-source-maps"
      }
    }
  }

  # auth = {
  #   image_file = "auth.jpg"
  #   css_file   = "auth.css"
  # }

  # dev_setup = {
  #   # enabled           = !local.is_prod
  #   local_website_url = "http://localhost:12345" # auth can redirect to that website, cors of http api allows origin
  # }

  providers = {
    aws = aws
    aws.us-east-1 = aws.us-east-1
  }
}
