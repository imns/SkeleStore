INSERT INTO documents (body) VALUES(json('{"id":2,"name":"Hy-Vee","items":[]}'));
UPDATE documents SET body = json('{"id":2,"name":"Kroger","items":[]}') WHERE id = 2;
