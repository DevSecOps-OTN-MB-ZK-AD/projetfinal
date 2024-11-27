terraform {
  required_version = ">= 1.5.7"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "> 2.23.0"
    }
  }
}

provider "kubernetes" {
  config_path = "C:/Users/MAziz/.kube/config"  # Ensure this points to your Minikube kubeconfig
}

# Create a Kubernetes namespace for the final project
resource "kubernetes_namespace" "final_project" {
  metadata {
    name = "final-project-devsecops"
  }
}

# Create a deployment with 2 replicas (scalable containers/pods) for the final project
resource "kubernetes_deployment" "final_project_app" {
  metadata {
    name      = "final-project-app"
    namespace = kubernetes_namespace.final_project.metadata[0].name
    labels = {
      app = "final-project-app"
    }
  }

  spec {
    replicas = 2  # Number of containers/pods to run

    selector {
      match_labels = {
        app = "final-project-app"
      }
    }

    template {
      metadata {
        labels = {
          app = "final-project-app"
        }
      }

      spec {
        container {
          name  = "final-project-container"
          image = "nginx:latest"  # Replace with your DockerHub image
          port {
            container_port = 80
          }
        }
      }
    }
  }
}

# Create a service to expose the final project app with load balancing
resource "kubernetes_service" "final_project_app" {
  metadata {
    name      = "final-project-service"
    namespace = kubernetes_namespace.final_project.metadata[0].name
  }

  spec {
    selector = {
      app = "final-project-app"
    }

    port {
      port        = 80
      target_port = 80
    }

    type = "LoadBalancer"  # NodePort for Minikube, change to LoadBalancer when migrating to cloud
  }
}
