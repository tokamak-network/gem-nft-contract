# Staking Index Oracle

## description

This script is an event listener which catches events ```Deposited``` and ```WithdrawalRequested``` emitted in L1WrappedStakedTON. the script is made to run within a docker container. To ensure the private key is safe, we encrypt it using docker secret. The private key is then not exposed publicly.

## Installation steps

Initialize the docker swarm
```
docker swarm init
```

creating the docker secret 
```
echo "your-private-key-content" | docker secret create my_private_key -
```

```
docker secret create private_key /tmp/private_key
```

You know you've done it right if you can see the secret key generated
```
docker secret ls
```
creating a new docker service using the secret generated
```
docker service create \
  --name fetchstakingindextitan-service \
  --secret private_key \
  fetchstakingindextitan
```

## How Docker Secret work ?

- Encrypted Storage: Docker secrets are stored in an encrypted format on the manager nodes of a Docker Swarm. They are only accessible to services that explicitly request them.
- Limited Access: Secrets are mounted as files in the /run/secrets/ directory inside the container. Only the container that is running the service has access to this directory, and the secret is not exposed to the environment variables or command-line arguments.
- In-Memory Access: The secret is only available in memory and is not written to disk inside the container. This reduces the risk of the secret being leaked through filesystem access.

## Best Practices to Ensure Security

- Limit Service Access: Only services that need access to the secret should be granted access. Avoid sharing secrets across multiple services unless absolutely necessary.
- Monitor and Rotate Secrets: Regularly monitor the usage of secrets and rotate them periodically. If you suspect that a secret has been compromised, rotate it immediately.
- Restrict Access to Manager Nodes: Since secrets are stored on manager nodes, ensure that access to these nodes is tightly controlled. Use firewalls, VPNs, and other security measures to protect the manager nodes.
- Avoid Logging Secrets: Be careful not to log the contents of secrets or paths to secret files. Ensure that your application does not inadvertently expose secrets in logs or error messages.

## Analysis

Here is the relevant part of the script that handles the private key:
```Go
privateKeyPath := "/run/secrets/private_key"
privateKeyBytes, err := ioutil.ReadFile(privateKeyPath)
if err != nil {
    log.Fatalf("Failed to read private key from Docker secret: %v", err)
}
privateKeyHex := strings.TrimSpace(string(privateKeyBytes))
```

- No Logging of Secret Contents:
    - The script reads the private key from the file and stores it in privateKeyHex.
    - The private key itself (privateKeyHex) is not logged anywhere in the script, which is good practice.
- No Logging of Secret File Paths:
    - The path to the secret file (/run/secrets/private_key) is used in the ioutil.ReadFile function, but it is not logged. This is compliant with the best practice.
- Sensitive Information Handling:
    - The script does not log any sensitive information derived from the private key, such as the private key itself or any derived addresses.

