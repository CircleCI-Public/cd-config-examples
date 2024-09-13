# CD Config Examples

This repository provides a set of guidelines and examples that demonstrate how to implement continuous delivery (CD) using CircleCI.

## Introduction

Continuous delivery (CD) is a software development practice in which code changes are automatically built, tested, and prepared for a release to production. Continuous delivery is an extension of continuous integration (CI), taking the concept a step further by deploying all code changes after the build stage.

An effective CI/CD setup monitors to ensure that the newly released version is in a stable state and ready to take on more responsibility or be promoted to other environments. This practice ensures that you can release a new version of your software quickly and sustainably, without dedicating resources to oversee the deployment of your software.

The examples in theis repo are designed to help you implement robust CI/CD pipelines using CircleCI. It contains practical examples and guidelines, providing a hands-on approach to setting up your own continuous delivery pipelines.

## Examples

* [Kubernetes release agent onboarding](./guidelines/k8s-release-agent-onboarding.md): Dive into the process of installing and using the CircleCI Kubernetes Release Agent. This example guides you through both local installation for rapid testing and cluster-based installation for real-time workload monitoring with CircleCI.

> [!NOTE]
> As time progresses, more guidelines will be added to this repository, and existing ones will be updated to reflect the evolution of CircleCI's Continuous Delivery offerings. Stay tuned for these enhancements!
