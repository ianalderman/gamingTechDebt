# Cloud Compliance Portal

## Intro ##
The goal of this project is to providing an example of how we can use cloud APIs to move to a continuos compliance model and leverage gamification to motivate teams

## About the architecture ##

- Simple to set-up
- Minimal cost

I explored <add link> using a static web site for this spending time with Jekyll and the Fluid framework (links).  I ended up giving up on this largely because I could not reconcile myself to having to do a deployment each day to update the report.  Instead I switched over to a NodeJS App to build the content and then use the free tier of Redis.  Why?  Looking at the architecture the most expensive component is going to be the database which will spend most of its time idle, following this thread I wanted to use the project as a demonstrator for the serverless tier (link).  Adding Redis or a static site enables me to avoid needlessly re-computing the same report each time someone hits the webpage.

# Lenses #

You could cut this various ways, presenting based on cost compliance - who has budgets, who has cost recommendations. Security etc.


