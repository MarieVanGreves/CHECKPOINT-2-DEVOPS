#!/bin/bash

# Variables pour la configuration DynV6 (Faut pas chercher pour le nom)
subdomain="ploopmaloop"
domain="dynv6.net"
dyndns_password="xccSJz5-s5ePEs8jSqKEfNRgay94GB"

# Connexion à la VM
sshpass -p Aptitude-Crinkle-Jittery3-Stoplight-Ambitious-Polygraph ssh marie@176.9.10.239 -p 22154 << 'EOF'
    # Partie 1.1 : Installation d'Ansible et configuration de l'inventaire
    sudo apt update
    sudo apt install ansible

    mkdir ~/ansible
    cd ~/ansible
    touch inventory

    echo "[debian]" >> inventory
    echo "debian_host ansible_host=176.9.10.239 ansible_user=marie ansible_ssh_pass=Aptitude-Crinkle-Jittery3-Stoplight-Ambitious-Polygraph" >> inventory

    # Partie 1.2 : Création des tâches des rôles Ansible
    # Insérez ici le code pour parcourir le fichier readme.md et créer les tâches dans les fichiers YAML des rôles

    # Partie 2 : Accès au Wordpress via un sous-domaine

    # Création d'un rôle pour la configuration du serveur web

    ansible-galaxy init apache_setup

    # Création d'un rôle pour la configuration de Let's Encrypt

    ansible-galaxy init certbot_setup

    # Configuration du serveur web avec Apache
    cat > apache_setup/tasks/main.yml << 'EOF_APACHE'
    ---
    - name: Install Apache
      apt:
        name: apache2
        state: present

    - name: Configure Apache virtual host
      template:
        src: apache_vhost.conf.j2
        dest: /etc/apache2/sites-available/wordpress.conf
      notify:
        - reload apache
      tags: apache
    EOF_APACHE

    cat > apache_setup/templates/apache_vhost.conf.j2 << 'EOF_APACHE_CONF'
    <VirtualHost *:80>
        ServerName {{ subdomain }}.{{ domain }}
        DocumentRoot /var/www/html/wordpress

        <Directory /var/www/html/wordpress>
            Options Indexes FollowSymLinks
            AllowOverride All
            Require all granted
        </Directory>

        ErrorLog ${APACHE_LOG_DIR}/error.log
        CustomLog ${APACHE_LOG_DIR}/access.log combined
    </VirtualHost>
    EOF_APACHE_CONF

    # Configuration de Let's Encrypt avec Certbot
    cat > certbot_setup/tasks/main.yml << 'EOF_CERTBOT'
    ---
    - name: Install Certbot
      apt:
        name: certbot
        state: present

    - name: Obtain TLS certificate with Certbot
      shell: "certbot certonly --apache -d {{ subdomain }}.{{ domain }} --non-interactive --agree-tos --email keiiskyx@gmail.com"
      args:
        executable: /bin/bash
      notify:
        - reload apache
      tags: certbot
    EOF_CERTBOT

    # Configuration de DynV6 pour la mise à jour de l'adresse IP
    cat > dynv6_update.sh << EOF_DYNV6
    #!/bin/bash
    curl -k "https://ipv4.dynv6.com/api/update?hostname=${subdomain}.${domain}&ipv4=\$(curl -s https://api64.ipify.org)"
    EOF_DYNV6
    chmod +x dynv6_update.sh

    # Exécuter la mise à jour DynV6 toutes les heures
    (crontab -l ; echo "0 * * * * ~/dynv6_update.sh") | crontab -

EOF
