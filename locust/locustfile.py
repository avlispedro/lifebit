from locust import task 


class WebsiteUser():
    wait_time = between(5, 15)
       
    @task
    def index(self):
        self.client.get("[Loadbalancer FQDN GOES HERE]")
