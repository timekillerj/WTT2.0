import os
import logging
import tornado.ioloop
import tornado.web
import motor.motor_tornado
from tornado.escape import json_encode
from bson import ObjectId
import datetime

logging.basicConfig(level=logging.DEBUG)

class MainHandler(tornado.web.RequestHandler):
    async def get(self):
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
        collection = db.backup_records
        
        # Perform the MongoDB query
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
        (r"/backups", MainHandler),
        (r"/static/(.*)", tornado.web.StaticFileHandler, {"path": "static"}),
    ])

if __name__ == "__main__":
    app = make_app()
    app.listen(8888)
    print("Listening on http://localhost:8888/backups")
    tornado.ioloop.IOLoop.current().start()
