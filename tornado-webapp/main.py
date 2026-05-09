import os
import logging
import tornado.ioloop
import tornado.web
import motor.motor_tornado
from tornado.escape import json_encode
from bson import ObjectId
import datetime
from jinja2 import Environment, FileSystemLoader, select_autoescape

logging.basicConfig(level=logging.DEBUG)

template_env = Environment(
    loader=FileSystemLoader(os.path.join(os.path.dirname(__file__), "templates")),
    autoescape=select_autoescape(["html", "xml"])
)

# Retrieve MongoDB connection details from environment variables
mongo_host = os.getenv('MONGO_HOST', 'localhost')
mongo_user = os.getenv('MONGO_USER', 'admin')
mongo_pass = os.getenv('MONGO_PASS', 'password')

# MongoDB connection string
connection_string = f'mongodb://{mongo_user}:{mongo_pass}@{mongo_host}:27017'
logging.debug(f'Connection: {connection_string}')

# MongoDB connection
client = motor.motor_tornado.MotorClient(connection_string)
db = client.backups


class IndexHandler(tornado.web.RequestHandler):
    async def get(self):
        template = template_env.get_template("index.html")

        html = template.render(
            title="Wiz Tech Task",
            message="My Super cool Tornado Webapp",
            hostname=os.uname().nodename
        )

        self.write(html)

class BackupsHandler(tornado.web.RequestHandler):
    async def get(self):
        # Perform the MongoDB query
        collection = db.backup_records
        cursor = collection.find({})
        documents = await cursor.to_list(length=None)
        
        # Convert MongoDB documents to JSON, handling ObjectId and datetime
        def convert_document(doc):
            for key, value in doc.items():
                if isinstance(value, ObjectId):
                    doc[key] = str(value)
                elif isinstance(value, datetime.datetime):
                    doc[key] = value.isoformat()
            return doc

        documents = [convert_document(doc) for doc in documents]
        
        # Set the response headers and write the JSON data
        self.set_header("Content-Type", "application/json")
        self.write(json_encode(documents))

def make_app():
    return tornado.web.Application([
        (r"/", IndexHandler),
        (r"/backups", BackupsHandler),
        (r"/static/(.*)", tornado.web.StaticFileHandler, {"path": "static"}),
    ])

if __name__ == "__main__":
    app = make_app()
    app.listen(8888)
    print("Listening on http://localhost:8888/backups")
    tornado.ioloop.IOLoop.current().start()
