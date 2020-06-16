Use this to make it easier to host a local instance of a flarum forum.
You can use `just`, or the bash script

```
just -l
Available recipes:
    start
    stop
    enter
    build
    logs

```


 ```
 ./devsite.sh                                                                                                                                    ledstrain.org -> master ! ?

	site should contain the flarum site files.
	sqlbin should contain the mysqldump of the database

	./devsite.sh start
	./devsite.sh stop
	./devsite.sh enter  # Enter web instance. Useful to install composer packages
	./devsite.sh build  # Rebuild the web image
	./devsite.sh logs   # Follow the web instance logs
  ```
