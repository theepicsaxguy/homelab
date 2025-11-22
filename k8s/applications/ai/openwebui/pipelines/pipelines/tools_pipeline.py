"""
title: General Tools
author: theepicsaxguy
description: Provides general utility tools including user info, current time, calculator, and weather
required_open_webui_version: 0.4.3
requirements: requests
version: 1.0.0
license: MIT
"""

import os
import requests
from datetime import datetime
from typing import List, Union, Generator, Iterator
from pydantic import BaseModel, Field

from logging import getLogger
logger = getLogger(__name__)
logger.setLevel("DEBUG")


class Pipeline:
    class Valves(BaseModel):
        OPENWEATHER_API_KEY: str = Field(
            default="",
            description="OpenWeather API key for weather functionality"
        )

    def __init__(self):
        self.name = "General Tools Pipeline"
        self.valves = self.Valves(
            **{k: os.getenv(k, v.default) for k, v in self.Valves.model_fields.items()}
        )

    async def on_startup(self):
        logger.debug(f"on_startup:{self.name}")
        pass

    async def on_shutdown(self):
        logger.debug(f"on_shutdown:{self.name}")
        pass

    def get_user_name_and_email_and_id(self, __user__: dict = {}) -> str:
        """
        Get the user name, Email and ID from the user object.
        """
        # Do not include a description for __user__ as it should not be shown in the tool's specification
        # The session user object will be passed as a parameter when the function is called

        logger.debug(f"User object: {__user__}")
        result = ""

        if "name" in __user__:
            result += f"User: {__user__['name']}"
        if "id" in __user__:
            result += f" (ID: {__user__['id']})"
        if "email" in __user__:
            result += f" (Email: {__user__['email']})"

        if result == "":
            result = "User: Unknown"

        return result

    def get_current_time(self) -> str:
        """
        Get the current time in a more human-readable format.
        """
        now = datetime.now()
        current_time = now.strftime("%I:%M:%S %p")  # Using 12-hour format with AM/PM
        current_date = now.strftime(
            "%A, %B %d, %Y"
        )  # Full weekday, month name, day, and year

        return f"Current Date and Time = {current_date}, {current_time}"

    def calculator(
        self,
        equation: str = Field(
            ..., description="The mathematical equation to calculate."
        ),
    ) -> str:
        """
        Calculate the result of an equation.
        WARNING: This uses eval() which can be a security risk.
        Only use in trusted environments or with proper input validation.
        """
        # Note: eval() is used here for flexibility but is a security risk
        # https://nedbatchelder.com/blog/201206/eval_really_is_dangerous.html
        # In production, consider using ast.literal_eval() or a math expression parser
        try:
            # Basic input validation to prevent obvious abuse
            # This is NOT comprehensive security - use at your own risk
            if any(keyword in equation for keyword in ['import', '__', 'exec', 'compile', 'open', 'file']):
                return "Invalid equation: potentially unsafe operations detected"
            result = eval(equation)
            return f"{equation} = {result}"
        except Exception as e:
            logger.error(f"Calculator error: {e}")
            return "Invalid equation"

    def get_current_weather(
        self,
        city: str = Field(
            "New York, NY", description="Get the current weather for a given city."
        ),
    ) -> str:
        """
        Get the current weather for a given city.
        """
        api_key = self.valves.OPENWEATHER_API_KEY
        if not api_key:
            return (
                "API key is not set in the environment variable 'OPENWEATHER_API_KEY'."
            )

        base_url = "http://api.openweathermap.org/data/2.5/weather"
        params = {
            "q": city,
            "appid": api_key,
            "units": "metric",  # Optional: Use 'imperial' for Fahrenheit
        }

        try:
            response = requests.get(base_url, params=params)
            response.raise_for_status()  # Raise HTTPError for bad responses (4xx and 5xx)
            data = response.json()

            if data.get("cod") != 200:
                return f"Error fetching weather data: {data.get('message')}"

            weather_description = data["weather"][0]["description"]
            temperature = data["main"]["temp"]
            humidity = data["main"]["humidity"]
            wind_speed = data["wind"]["speed"]

            return f"Weather in {city}: {weather_description}, {temperature}°C, Humidity: {humidity}%, Wind: {wind_speed} m/s"
        except requests.RequestException as e:
            logger.error(f"Weather API error: {e}")
            return f"Error fetching weather data: {str(e)}"

    def pipe(
        self,
        user_message: str,
        model_id: str,
        messages: List[dict],
        body: dict
    ) -> Union[str, Generator, Iterator]:
        """
        Main pipeline function. Routes requests to appropriate tool functions.
        """
        logger.debug(f"pipe:{self.name}")
        logger.info(f"User Message: {user_message}")

        # This is a tools pipeline - tools are typically invoked by the LLM
        # The actual tool calling mechanism would be handled by OpenWebUI
        # For now, return a simple response
        return "General Tools Pipeline is active. Tools available: get_user_name_and_email_and_id, get_current_time, calculator, get_current_weather"
