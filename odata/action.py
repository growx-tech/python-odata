# -*- coding: utf-8 -*-

try:
    # noinspection PyUnresolvedReferences
    from urllib.parse import urljoin
except ImportError:
    # noinspection PyUnresolvedReferences
    from urlparse import urljoin
from collections import OrderedDict

from odata.connection import ODataConnection


class Action(object):

    def __init__(self, qualified_name, **def_kwargs):
        self.qualified_name = qualified_name
        self._def_kwargs = def_kwargs
        self._returns_def_kwargs = {}

        self._entity_cls = None

    def __get__(self, instance, owner):
        self._entity_cls = owner
        return self

    def __call__(self, **kwargs):
        url = self._entity_cls.__odata_url__()
        url = url + '/' + self.qualified_name
        connection = self._entity_cls.__odata_connection__  # type: ODataConnection

        response_data = self._execute_http(connection, url, kwargs)
        response_data = (response_data or {}).get('value', {})

        if self._returns_def_kwargs and response_data:
            return_data = OrderedDict()
            for key, value in response_data.items():
                prop_type = self._returns_def_kwargs.get(key)
                return_data[key] = prop_type('temp').deserialize(value)
            return return_data
        return response_data

    def _execute_http(self, connection, url, kwargs):
        # Execute http POST, encoding kwargs to json body
        data = OrderedDict()
        for key, value in kwargs.items():
            prop_type = self._def_kwargs.get(key)
            escaped_value = prop_type('temp').serialize(value)
            data[key] = escaped_value

        return connection.execute_post(url, data)

    def returns(self, **def_kwargs):
        self._returns_def_kwargs = def_kwargs
        return self


class Function(Action):
    def _execute_http(self, connection, url, kwargs):
        # Execute http GET, passing kwargs as parameters in url
        kwargs_escaped = []
        for key, value in kwargs.items():
            prop_type = self._def_kwargs.get(key)
            escaped_value = prop_type('temp').escape_value(value)
            kwargs_escaped.append((key, escaped_value))

        kwargs_escaped = sorted(kwargs_escaped, key=lambda x: x[0])
        params = ['='.join([key, str(value)]) for key, value in kwargs_escaped]
        params = ','.join(params)
        url += '({0})'.format(params)

        return connection.execute_get(url)
