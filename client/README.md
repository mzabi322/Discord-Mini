# TP MiniDiscord - Client
Dans cette partie on a créé le client du MiniDiscord.

Le client se connecte au serveur avec une socket TCP grâce à la fonction :

:gen_tcp.connect(String.to_charlist(host), port, [:binary, packet: :line, active: false])

Les options utilisées sont :
1. :binary : les messages sont reçus sous forme binaire ;
2. packet: :line : les messages sont lus ligne par ligne ;
3. active: false : le client lit manuellement les messages avec :gen_tcp.recv/2.

Après la connexion le client appelle la fonction rencontre(socket).

Afin de permettyre au client d'envoyer et de recevoir des messages on lance La tâche receive_loop qui sert à recevoir les messages du serveur et la tâche send_loop sert à lire les messages tapés par l'utilisateur et à les envoyer au serveur.
 ## 2. Robustesse
Afin de  tester la robustess on va simuler une panne du serveur en tuant le processus MiniDiscord.ChatServer depuis le terminal du serveur en executant : '''Process.whereis(MiniDiscord.ChatServer) |> Process.exit(:kill)'''
Au depart avant config le client affiche seulement un message de déconnexion et s’arrête.

# 2.3 Robustesse OTP
OTP permettrait de rendre le programme plus solide. Dans notre code on gère la reconnexion nous meme : si une erreur arrive le client attend puis essaie de se reconnecter.
Avec OTP, ce travail pourrait être fait plus proprement grâce à un superviseur 
Si un processus plante, le superviseur peut le détecter et le redémarrer automatiquement.
Cela éviterait de mettre du code de gestion d’erreur partout. Le programme serait donc plus fiable, surtout avec plusieurs processus comme le serveur,les clients ou les salons

# 2.4 
## 2.4. Filtrage de message

Dans cette partie, j’ai ajouté une fonction `valider_message(msg)` pour contrôler les messages envoyés et reçus par le client.

Cette fonction vérifie que le message n’est pas vide, qu’il ne dépasse pas 500 caractères et qu’il ne contient pas certains caractères interdits comme `\`, `?`, `<` ou `>`.

Si le message n’est pas valide, la fonction retourne une erreur.

Cette fonction est utilisée dans `send_loop` avant l’envoi du message au serveur. Elle est aussi utilisée dans `receive_loop` avant l’affichage d’un message reçu. Cela permet d’éviter d’envoyer ou d’afficher des messages problématiques.

