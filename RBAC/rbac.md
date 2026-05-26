apiVersion: v1
kind: Namespace
metadata:
  name: techpilotz
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: techpilotz
  namespace: techpilotz
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: techpilotz-role
  namespace: techpilotz
rules:
  # Permissions for core API resources
  - apiGroups: [""]
    resources:
      - secrets
      - configmaps
      - persistentvolumeclaims
      - services
      - pods
    verbs: ["get", "list", "watch", "create", "update", "delete", "patch"]

  # Permissions for apps API group
  - apiGroups: ["apps"]
    resources:
      - deployments
      - replicasets
      - statefulsets
    verbs: ["get", "list", "watch", "create", "update", "delete", "patch"]

  # Permissions for networking API group
  - apiGroups: ["networking.k8s.io"]
    resources:
      - ingresses
    verbs: ["get", "list", "watch", "create", "update", "delete", "patch"]

  # Permissions for autoscaling API group
  - apiGroups: ["autoscaling"]
    resources:
      - horizontalpodautoscalers
    verbs: ["get", "list", "watch", "create", "update", "delete", "patch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: techpilotz-rolebinding
  namespace: techpilotz
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: techpilotz-role
subjects:
  - kind: ServiceAccount
    name: techpilotz
    namespace: techpilotz
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: techpilotz-cluster-role
rules:
  # Permissions for persistentvolumes
  - apiGroups: [""]
    resources:
      - persistentvolumes
    verbs: ["get", "list", "watch", "create", "update", "delete"]
  # Permissions for storageclasses
  - apiGroups: ["storage.k8s.io"]
    resources:
      - storageclasses
    verbs: ["get", "list", "watch", "create", "update", "delete"]
  # Permissions for ClusterIssuer
  - apiGroups: ["cert-manager.io"]
    resources:
      - clusterissuers
    verbs: ["get", "list", "watch", "create", "update", "delete"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: techpilotz-cluster-rolebinding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: techpilotz-cluster-role
subjects:
  - kind: ServiceAccount
    name: techpilotz
    namespace: techpilotz