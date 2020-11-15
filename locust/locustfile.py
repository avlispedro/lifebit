from locust import task, between,HttpUser


class WebsiteUser(HttpUser):
    wait_time = between(5, 15)
       
    @task
    def index(self):
        self.client.get("http://elb-826097473.eu-west-2.elb.amazonaws.com/")
