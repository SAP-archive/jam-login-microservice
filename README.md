# jam-login-microservice

Single sign-on reverse proxy that you can add to your application stack.
Handles all http requests before they reach the application and ensures
the user is authenticated. Currently supports SAML as the authentication
protocol. User identity information sent by the identity provider is
passed to the application in a header.

  * Docker based. Easy to deploy.
  * Your application can be in any language.

## Requirements

  * Requires [Redis](https://hub.docker.com/_/redis) for session store.

## Download and Installation

Clone this project and follow the steps in the next section.

## Configure, build, deploy

  * Edit the configuration in phoenix/config/config.exs
    * set idps, subdomain, tenants, jwt_hs256_secret config in this file
  * Edit the registry in docker/build.sh and build
  * Deploy with your favorite container orchestration framework (Kubernetes, et al)
  * Point your http load-balancer to jam-login-microservice
  * Ensure Redis is running at the default port

## API

  * Adds header, "Authentication" with content
    * Bearer *jwt_token*
  * JWT Token contains a payload with user identity information
    * email
  * Shared secret is used for JWT digital signature

## How to obtain support

Use the issues tab on this Github project to search for or create an issue.

## Contributing

Fork this project, edit and create a pull request.

## License

Copyright (c) 2019 SAP SE or an SAP affiliate company. All rights reserved.
This file is licensed under the Apache Software License, v. 2 except as noted otherwise in the LICENSE file.
