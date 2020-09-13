FROM mcr.microsoft.com/dotnet/core/sdk:3.1

EXPOSE 80 443
ENV ASPNETCORE_URLS http://+:80
ENV ASPNETCORE_ENVIRONMENT Production
ENV DOTNET_RUNNING_IN_CONTAINER=true

WORKDIR /app
COPY src/.build/release .
COPY init.sh .

RUN chmod +x ./initialise.sh
CMD /bin/bash ./initialise.sh