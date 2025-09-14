FROM rocker/shiny:4.1.2 

# Installer dépendances système nécessaires
RUN apt-get update && apt-get install -y \
    libssl-dev \
    libcurl4-openssl-dev \
    libxml2-dev \
    && rm -rf /var/lib/apt/lists/*

# Installer remotes
RUN R -e "install.packages('remotes', repos='https://cloud.r-project.org')"

# Installer les packages nécessaires
RUN R -e "remotes::install_cran(c( \
    'shiny', 'plotly', 'DT', 'readr', 'dplyr', 'tidyr', \
    'lubridate', 'scales', 'cachem', 'digest' \
  ))"

# Créer le dossier de ton app dans le conteneur
RUN mkdir -p /srv/shiny-server/shinyfinances

# Copier ton application dans le conteneur
COPY . /srv/shiny-server/shinyfinances

# Supprimer la page d'accueil par défaut
RUN rm -rf /srv/shiny-server/index.html

# Donner les bons droits à l'utilisateur shiny
RUN chown -R shiny:shiny /srv/shiny-server

# Exposer le port Shiny
EXPOSE 3838

# Lancer Shiny Server
CMD ["/usr/bin/shiny-server"]
