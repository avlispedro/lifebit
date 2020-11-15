from locust import task, between,HttpUser


class WebsiteUser(HttpUser):
    wait_time = between(5, 15)
       
    @task
    def index(self):
        self.client.get("[Loadbalancer FQDN GOES HERE]")
