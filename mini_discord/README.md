**Question**

Q1. Pourquoi utilise-t-on Process.monitor/1 dans handle_call({:rejoindre}) ?

On utilise Porcess.monitor pour que le salon soit prévenu quand un client quitte ou meurt

Q2. Que se passe-t-il si on n'implémente pas handle_info({:DOWN, ...}) ? 

Le handle_info sert a gerer les messages "auto" recues par le GenServer qui ne vient pas d'un call ou d'un cast.Si un client quitte/crash, handle_info le supprime automatiquement du salon.
Le GenServer recevra quand même les messages `{:DOWN, ...}`, mais sans handler il risque de crasher sur un message non géré. Dans le meilleur cas, les processus morts s'accumulent dans `clients` et le salon continue de leur envoyer des messages inutilement ce qui vas crreer un état incohérent.

Q3. Quelle est la différence entre handle_call et handle_cast ? Pourquoi broadcast est un cast ?
  -handle_call est un appel synchrone il attend une réponse on  l’utilise quand on veut savoir si l’action a réussi.
  - handle_cast est un appel asynchrone, le processus envoie un message au GenServ mais n'attends pas de réposne.

  broadcast est un cast parce qu’on veut seulement envoyer le message à tous les clients du salon. L’émetteur n’a pas besoin d’attendre une réponse du serveur, donc c’est plus rapide et non bloquant

Phase 2. Questions

2-4. Le salon redémarre-t-il après le kill ? Pourquoi ? 
Oui le salon redémarre ici apres le kill on peut le voir en se connectant sur le salon on le toruve encore present.C'est grace au superviseur que le salon se relance des que le superviseur détecte que ce processus.


2-5. Quelle est la différence entre les stratégies :one_for_one et :one_for_all ?

La différence ente les stratégies one_for_one et one_for_all c'est que la stratégie one_for_one si un processus child crash seul ce processus va redemarré cependant le one_for_all si un processus child crash tous les processus chils sont arretes et redemarres.