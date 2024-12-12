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
  config_path = "C:/Users/owner/.kube/config"  # Ensure this points to your Minikube kubeconfig
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
          image = "oliviertremblaynoel/log8100-projet"
          port {
            container_port = 8080
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
      port        = 8080
      target_port = 8080
    }

    type = "LoadBalancer"
  }
}

## ConfigMap for prometheus.yml but need to change it 
resource "kubernetes_config_map" "prometheus_config" {
  metadata {
    name      = "prometheus-config"
    namespace = kubernetes_namespace.final_project.metadata[0].name
  }

  data = {
    "prometheus.yml" = <<EOT
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'kube-state-metrics'
    static_configs:
      - targets: ['kube-state-metrics.final-project-devsecops.svc.cluster.local:8080']

  - job_name: 'webgoat'
    metrics_path: '/WebGoat/actuator/prometheus' 
    static_configs:
      - targets: ['final-project-service.final-project-devsecops.svc.cluster.local:8080']

  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
EOT
  }
}

# déploiement de Prometheus
resource "kubernetes_deployment" "prometheus" {
  metadata {
    name      = "prometheus" # Nom du déploiement
    namespace = kubernetes_namespace.final_project.metadata[0].name
    labels = {
      app = "prometheus" # Étiquette pour identifier les pods
    }
  }

  spec {
    replicas = 1 # Un seul pod pour Prometheus

    selector {
      match_labels = {
        app = "prometheus"
      }
    }

    template {
      metadata {
        labels = {
          app = "prometheus"
        }
      }

      spec {
        container {
          name  = "prometheus" # Nom du conteneur
          image = "prom/prometheus:latest" # Image Docker de Prometheus
          port {
            container_port = 9090 # Port utilisé par Prometheus
          }
          volume_mount { 
            name       = "prometheus-config-volume"
            mount_path = "/etc/prometheus/prometheus.yml" 
            sub_path   = "prometheus.yml" 
          } 
        }
        volume { 
          name = "prometheus-config-volume" 

          config_map { 
            name = kubernetes_config_map.prometheus_config.metadata[0].name 
          } 
        } 
      }
    }
  }
}

# Service pour  Prometheus
resource "kubernetes_service" "prometheus" {
  metadata {
    name      = "prometheus-service" # Nom du service
    namespace = kubernetes_namespace.final_project.metadata[0].name
  }

  spec {
    selector = {
      app = "prometheus" 
    }

    port {
      port        = 9090 # Port exposé par le service
      target_port = 9090 # Port du conteneur Prometheus
    }

    type = "LoadBalancer" # Permet un accès externe
  }
}

#  déploiement de Grafana
resource "kubernetes_deployment" "grafana" {
  metadata {
    name      = "grafana" 
    namespace = kubernetes_namespace.final_project.metadata[0].name
    labels = {
      app = "grafana" 
    }
  }

  spec {
    replicas = 1 # Un seul pod pour Grafana

    selector {
      match_labels = {
        app = "grafana"
      }
    }

    template {
      metadata {
        labels = {
          app = "grafana"
        }
      }

      spec {
        container {
          name  = "grafana" # Nom du conteneur
          image = "grafana/grafana:latest" # Image Docker de Grafana
          port {
            container_port = 3000 # Port utilisé par Grafana
          }
        }
      }
    }
  }
}

#  Service pour  Grafana
resource "kubernetes_service" "grafana" {
  metadata {
    name      = "grafana-service" # Nom du service
    namespace = kubernetes_namespace.final_project.metadata[0].name
  }

  spec {
    selector = {
      app = "grafana" # Lie le service au déploiement via l'étiquette
    }

    port {
      port        = 3000 # Port exposé par le service
      target_port = 3000 # Port du conteneur Grafana
    }

    type = "LoadBalancer" # Permet un accès externe
  }
}


# Déploiement de kube-state-metrics
resource "kubernetes_deployment" "kube_state_metrics" {
  metadata {
    name      = "kube-state-metrics"
    namespace = kubernetes_namespace.final_project.metadata[0].name
    labels = {
      app = "kube-state-metrics"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "kube-state-metrics"
      }
    }

    template {
      metadata {
        labels = {
          app = "kube-state-metrics"
        }
      }

      spec {
        container {
          name  = "kube-state-metrics"
          image = "registry.k8s.io/kube-state-metrics/kube-state-metrics:v2.9.2"

          port {
            container_port = 8080
          }
        }
      }
    }
  }
}

# Service pour kube-state-metrics
resource "kubernetes_service" "kube_state_metrics" {
  metadata {
    name      = "kube-state-metrics"
    namespace = kubernetes_namespace.final_project.metadata[0].name
  }

  spec {
    selector = {
      app = "kube-state-metrics"
    }

    port { 
      port        = 8080
      target_port = 8080
    }

    type = "ClusterIP" 
  }
}