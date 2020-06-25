from locust import HttpLocust, TaskSet, task, between

class WebTasks(TaskSet):
    @task(2)
    def index(self):
        self.client.get("/nnrf-nfm/v1/nf-instances")

    @task(1)
    def about(self):
        self.client.get("/nnrf-nfm/v1/nf-instances/6faf1bbc-6e4a-4454-a507-a14ef8e1bc5e")

class Web(HttpLocust):
    task_set = WebTasks
    wait_time = between(1, 3)