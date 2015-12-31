# Heroku Meets Azure - The Easiest Way to Deploy Your Rails App on Azure 

--
[Heroku](http://heroku.com) pretty much created the gold standard of Platform as a Service (PaaS) web deployments for open source web stacks based on Ruby, Python, Node and Php.

Microsoft Azure also offers a similar service as Heroku called [Azure Websites](http://azure.microsoft.com/en-us/services/websites/). This service handles automagic deployments via Git and popular source control providers like [Github](http://github.com) and [Bitbucket](http://bitbucket.com). 

Although Azure Websites has support for .NET and mostly supports PHP, Node, and Python it has no support for Ruby. In addition some things like [native modules](http://azure.microsoft.com/en-us/documentation/articles/nodejs-use-node-modules-azure-apps/) are not supported on the platform. 

Also, Azure Websites under the covers is Windows-based and there is no Linux option, making some subtle Windows-specific issues appear in your deployment environment when it may not happen in your development environment.

I did some digging and there's a great open-source framework called [Dokku](https://github.com/progrium/dokku) which is basically Heroku-in-a-box. That means that you can run all of your open source stacks with a simple `git push` command on Azure. 

Dokku will automatically launch your Ruby, PostgreSql, Node, Python, MongoDB etc services easily with docker containers. What does this mean?

**YOU CAN BASICALLY RUN HEROKU ON AZURE**

(well not exactly but you get the point)

How awesome is that?

Keep reading for this quick how-to:

# Getting Started with Dokku

Before you get started, you're gonna need your own Domain name. The way it works is that Dokku will place your apps in subdomains of the domain that you give it. This is called **Virtual Host Naming**. You can use any domain name registrar or you can use [xip.io](http://xip.io) to use your public ip address as a domain name:

```
http://rails-app.222.222.222.xip.io
http://node-app.222.222.222.xip.io
```

You can follow the [Dokku official Documentation for Azure](http://progrium.viewdocs.io/dokku/getting-started/install/azure/) which will have you [deploy the template to azure](https://azure.microsoft.com/en-us/documentation/templates/dokku-vm/).

After you've completed the deployment continue reading.

## Setting up a Domain Name

If you decide to get a domain name from a registrar like [Godaddy](http://godaddy.com) or [Namecheap](http://namecheap.com) you'll need to setup an A record to point to your Dokku instance on Azure.

In your DNS zone file create two A entries:

From  | To
------------- | -------------
@  | (your azure public ip)
*  | (your azure public ip)

Browse to the [Azure portal](http://portal.azure.com) and navigate to the resource group you deployed your Template to. You can get your public IP address from the Public IP blade which is inside the Resource Group blade.

![](ScreenShots/ss5.png)

In your browser of choice, navigate to `http://[[dnsNameForPublicIP]].[[location]].cloudapp.azure.com`. Where [[dnsNameForPublicIP]] and [[location]] are template parameters you used to deploy the template. You'll see the Dokku admin page waiting for you:

![](ScreenShots/ss4.png)

You can test if your DNS Zone settings are working correctly because browsing to `http://yourdomain.com` will also show the Dokku setup page. Now you have your domain setup!


## Configuring Dokku


The first thing Dokku setup page wants from you is your deployment public key. This is super easy to do, just do:

```bash
cd ~/.ssh
ssh-keygen 
# this is the path where you want your new key to be
.dokku-deploy
# enter a good passphrase
ls
# now you'll see two files dokku-deploy and dokku-deploy.pub
# copy the output from the command below
cat .dokku-deploy.pub
```

Now copy+paste the output of the public key to the 'public key' box on the dokku setup website.

**Note**: You shouldn't use the same SSH public key you used to deploy the template. Instead be sure to create a new one for dokku deployments.

Next, enter your domain name (such as `my_dokku_host.com`, or `10.72.29.23.xip.io`), by default Dokku will just launch your app to a specific port checking off `Use virtual host naming` allows you to use a domain name prefix for your app.

That's it! The web page should redirect you to the [dokku documentation](http://dokku.viewdocs.io/dokku/application-deployment/) page afterwards. 

## Deploying your Rails App

This guide goes into launching a Ruby app but you can easily launch most other types of apps to!

You can use your current Rails app or Clone [this app](https://github.com/sedouard/dokku-azure) as an example. This app is a 'restaurant reservation' app and cut me some slack, aside from not being the worlds best front-end developer, I built it within 24 hours of learning Ruby and Rails :-).

The app requires a PostgreSql server and we'll deploy that after deploying the app.

In your git repository add a new remote to your server:

```bash
git remote add dokku dokku@<your_domain_name>:app_name
# you can also use the public ip
git remote add dokku dokku@72.42.11.24:app_name
```

Note that using the user name `dokku` is required!

Add your corresponding ssh private key for the public deployment key you entered in the Dokku setup page:

```
# if your ssh-agent isn't already running run this command
eval `ssh-agent -s`
# now add the dokku deployment private key to your agent
ssh-add .dokku-deploy
```

Now just push the repository! Your ssh key you created in your `~/.ssh` folder should authenticate you. The remote repository is created on-the-fly by Dokku.

```
git push dokku master
remote: -----> Building rails-app2 using buildstep...
remote: -----> Installing ENV in build environment ...
-----> Using u1000 to run an application
-----> Ruby app detected
-----> Compiling Ruby/Rails
-----> Using Ruby version: ruby-2.0.0
...blah...blah...blah
remote: -----> Injecting git revision
remote: -----> Releasing rails-app2 ...
remote: -----> Deploying rails-app2 ...
remote: -----> Shutting down old containers
remote: =====> Application deployed:
remote:        http://yourapp.yourdomain.com
remote: -----> Cleaning up ...
```

Note: if you do this for your own app, make sure that you include a Procfile like [this one](https://github.com/sedouard/rails-restaurant/blob/master/Procfile). If you're already familiar with Heroku you'll know that its required for Heroku apps.


## Setting up Postgres

Finally this app needs to have a database, if you notice, browsing to your app doesn't work. That’s because you need to tell dokku to launch and link a Postgres database to your app. This is really easy though because Dokku comes with a variety of [plugins](http://dokku.viewdocs.io/dokku/plugins/#official-plugins-beta). In this app, you'll see that our [database.yml](config/database.yml) contains a URL with an environment variable that is injected by Dokku:

```
production:
  <<: *default
  database: my_database_production
  url: <%= ENV['DATABASE_URL'] %>
```

To do this, ssh into the Dokku VM using the login you specified in the Dokku template:

```
# be sure to ssh-add your VM login private key
ssh vm_username@your_domain.com
```

Tell Dokku you want install the postgres plugin:

``` 
sudo dokku plugin:install https://github.com/dokku/dokku-postgres.git postgres
```

Now create the postgres database:

```
dokku postgres:create my-postgres
```

Linking your Postgresql database container to your Rails app container is easy:

```
dokku postgres:link my-postgres app_name
```

**Important:** app_name must be the name of the app you deployed!


Since we're using rails, we have to do a database migration. In order to do this, we can tell dokku to run the `rake` command within the Rails container by simply doing:

```
dokku run app_name rake db:migrate
```

And thats it! Navigate to `http://app_name.your_domain.com` and you should see my super basic app running:

![](ScreenShots/ss1.png)

Try creating a reservation and viewing them, this demonstrates that the database is actually up and running on your Dokku host.

## In Closing...

Hope this helps you get your own 'Heroku' running on your cloud platform of choice. 

With Dokku, you can pretty much run your entire application stack and it takes a lot of the nuances away of running particular services with the speed of docker containers. What's even more awesome are the plugins for the various types of databases you may want to launch as well.

You can see this as a great alternative to Azure Websites if you're looking to run ruby on rails or just things that don't work quite right on Windows. Although it doesn't have the scale of Azure Websites, so if you're looking for scalability and the friendliness of Dokku checkout the [deis project](http://deis.io).

Go fourth and conquer!


