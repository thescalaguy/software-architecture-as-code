workspace {

    model {
        user = softwareSystem "Client"
        notificationSystem = softwareSystem "Notification System" {

            tags "internal"

            api = container "API" "Receives requests to send notifications" "Python" "internal"

            db = container "Database" "Stores the status of each request to send a notification" "Postgres" {
                tags "internal, database"
            }

            email = container "Email Consumer" "Sends emails" "Python" "internal"
            ios = container "iOS Consumer" "Sends iOS push notifications" "Python" "internal"
            android = container "Android Consumer" "Sends Android push notifications" "Python" "internal"

        }

        sendgrid = softwareSystem "Sendgrid"
        apns = softwareSystem "Apple Push Notification Service"
        fcm = softwareSystem "Firebase Cloud Messaging"
        cdc = softwareSystem "Change Data Capture" "Debezium"
        warehouse = softwareSystem "Data Warehouse"

        # -- Relationships between systems
        user -> api "Uses"
        api -> email "Enqueues request to send emails, through Kafka, to"
        email -> sendgrid "Sends emails using"

        api -> ios "Enqueues request to send push notifications, through Kafka, using"
        ios -> apns "Sends push notifications using"

        api -> android "Enqueues request to send push notifications, through Kafka, using"
        android -> fcm "Sends push notifications using"

        cdc -> db "Reads databse changes from"
        cdc -> warehouse "Writes database changes to"

        # -- Relationships between components
        api -> db "Stores incoming request in"  

        # -- Deployment view (Development)
        development = deploymentEnvironment "Development" {
            deploymentNode "Laptop" {
                containerInstance api
                containerInstance email
                containerInstance ios
                containerInstance android
                containerInstance db
            }

            deploymentNode "Third-Party Services" "Development" {
                softwareSystemInstance sendgrid
                softwareSystemInstance fcm
                softwareSystemInstance apns
            }
        }

        # -- Deployment view (Production)
        production = deploymentEnvironment "Production" {
            deploymentNode "Amazon Web Services" {
                tags "Amazon Web Services - Cloud"

                deploymentNode "US-East-1" {
                    tags "Amazon Web Services - Region"

                    route53 = infrastructureNode "Route 53" {
                        tags "Amazon Web Services - Route 53"
                    }

                    elb = infrastructureNode "Elastic Load Balancer" {
                        tags "Amazon Web Services - Elastic Load Balancing"
                    }

                    deploymentNode "Amazon RDS" {
                        tags "Amazon Web Services - RDS"

                        deploymentNode "Postgres" {
                            tags "Amazon Web Services - RDS Postgres instance"
                            containerInstance db
                        }
                    }

                    deploymentNode "API Servers" {
                        tags "Amazon Web Services - EC2"
                        
                        deploymentNode "Ubuntu Server" {
                            apiInstance = containerInstance api
                        }
                    }

                    deploymentNode "Email Consumers" {
                        tags "Amazon Web Services - EC2"
                        
                        deploymentNode "Ubuntu Server" {
                            containerInstance email
                        }
                    }
                }

                route53 -> elb "Forwards requests to" "HTTPS"
                elb -> apiInstance "Forwards requests to" "HTTPS"
            }

            deploymentNode "Third-Party Services" "Production" {
                softwareSystemInstance sendgrid
            }
        }
    }

    views {
        systemLandscape notificationSystem "Overview" {
            include *
            autoLayout lr
        }

        systemContext notificationSystem "Context" {
            include *
            autoLayout lr
        }

        container notificationSystem "Container" {
            include *
            autoLayout tb
        }

        deployment * development {
            include *
            autoLayout lr
        }

        deployment * production {
            include *
            autoLayout lr
        }

        !include ./commons/styles/default.dsl

        dynamic notificationSystem {
            title "Send an email notification"
            user -> api "Sends request to trigger an email notification to"
            api -> db "Stores the incoming request in"
            api -> email "Enqueues the request in Kafka for"
            email -> sendgrid "Sends email using"
            autoLayout lr
        }

        theme https://static.structurizr.com/themes/amazon-web-services-2023.01.31/theme.json
    }

}