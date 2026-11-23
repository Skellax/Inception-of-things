# IoT - Partie 1 : K3s + Vagrant

## Contexte
Ce projet lance deux VM via vagrant  l'une est configure en tant que server et l'autre en tant que server worker :
- `mfuhrmanS` : serveur K3s (control-plane)
- `mfuhrmanSW` : worker K3s (agent)

## Réseau et machines
- Server : `mfuhrmanS` / hostname `mfuhrmanS`
- Worker : `mfuhrmanSW` / hostname `mfuhrmanSW`
- IP serveur : `192.168.56.110`
- IP worker : `192.168.56.111`
- Box utilisée : `debian/bookworm64`
- Box URL : `https://vagrantcloud.com/debian/bookworm64`

## Structure du dépôt
- `p1/` : partie obligatoire K3s + Vagrant
- `p2/` : partie 2 du projet
- `p3/` : partie 3 du projet
- `bonus/` : bonus éventuel

## Commandes utiles
Depuis le dossier racine du projet :

```bash
cd /home/mfuhrman/IoT/p1
vagrant validate
vagrant up
vagrant status
```

Pour relancer uniquement un VM :

```bash
vagrant provision mfuhrmanS
vagrant provision mfuhrmanSW
```

Pour se connecter en SSH :

```bash
vagrant ssh mfuhrmanS
vagrant ssh mfuhrmanSW
```

Pour vérifier le cluster K3s côté serveur :

```bash
vagrant ssh mfuhrmanS -- sudo k3s kubectl get nodes -o wide
vagrant ssh mfuhrmanS -- sudo k3s kubectl get pods -A
```

Pour vérifier le statut des services :

```bash
vagrant ssh mfuhrmanS -- sudo systemctl status k3s
vagrant ssh mfuhrmanSW -- sudo systemctl status k3s-agent
```

Pour réinitialiser proprement les VMs :

```bash
destroy -f
# ou
vagrant destroy -f mfuhrmanS mfuhrmanSW
```

## Notes importantes
- Le serveur K3s doit utiliser le mode `server` et le worker doit utiliser le mode `agent`.
- Le token du worker est généré côté serveur dans : `/var/lib/rancher/k3s/server/node-token`
- Il est ensuite copié vers le dossier partagé Vagrant : `/vagrant/node-token`
- L’agent lit ce token puis le transmet dans sa config K3s.
- Le fichier principal du serveur est : `/etc/rancher/k3s/config.yaml`
- Le fichier principal de l’agent est : `/etc/rancher/k3s/config.yaml`
- Pour K3s, il est important d’attendre que le serveur soit prêt avant d’installer l’agent.
- Le service K3s côté server est `k3s` ; le service côté agent est `k3s-agent`.

## Vérification de la partie 1
Quand la configuration est correcte, on doit voir 2 nœuds dans le cluster :

```bash
vagrant ssh mfuhrmanS -- sudo k3s kubectl get nodes
```

Résultat attendu :
- `mfuhrmanS` : Ready, control-plane
- `mfuhrmanSW` : Ready, agent

## Remarques de dépannage
- Si le worker attend indéfiniment le token : vérifier `/vagrant/node-token` sur le serveur.
- Si l’agent ne rejoint pas le cluster : vérifier que le serveur est bien `Ready` et que le port `6443` répond.
- Si `curl https://get.k3s.io` pose problème : vérifier l’accès réseau dans la VM.
- Si le système est trop lent, éviter d’augmenter les ressources trop haut par rapport au sujet (le but est d’avoir une config minimale, 1 CPU et 1024 Mo).
