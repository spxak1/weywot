#rsync -uvP /home/otheos/ ceres:weywot
rsyncy -avPz --delete /home/otheos/ ceres:weywot --exclude=.cache --exclude=100MEDIA --exclude=CacheStorage --exclude=Cache
