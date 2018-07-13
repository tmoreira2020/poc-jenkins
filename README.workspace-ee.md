# Liferay Workspace EE

Liferay Workspace EE is an extension of [Liferay Workspace](https://github.com/david-truong/liferay-workspace), providing extra features around the same project structure that Liferay Workspace defines. You can get the latest version of Liferay Workspace EE from GitHub / Nexus, please see instructions in GitHub:

* [https://github.com/liferay/lfrgs-liferay-ironman/tree/master/liferay-build-tool/liferay-workspace-ee](https://github.com/liferay/lfrgs-liferay-ironman/tree/master/liferay-build-tool/liferay-workspace-ee) 

## Build configuration

### Project-specific properties (gradle.properties)

[gradle.properties](gradle.properties) is a standard Gradle file used to store configuration of the build. These properties are typically project-wide and there should be no need for each user to customize these. The master set of these properties should be maintained in [gradle.properties](gradle.properties) and committed into SCM.

All the properties used by Liferay Workspace EE share common prefix `liferay.workspace.ee.`, similar to properties from Liferay Workspace (CE) which all start with `liferay.workspace.`.

For complete list of supported EE properties, their description and default values, please see [gradle.workspace-ee-defaults.properties](gradle.workspace-ee-defaults.properties).

### User-specific properties (init script or command line options)

The build sometimes needs a few configuration properties, which likely will be different for each project's user (or project's CI server) building the sources. 

These are typically credentials to remote systems (Jenkins, AWS) or paths to external executables used by the build (like Packer). Even though these could be set in [gradle.properties](gradle.properties) as well, you should not do so. You will prevent committing your private information / settings into SCM, by for example accidentally including [gradle.properties](gradle.properties) in the commit.

You should use init script or command line options to provide values of these properties. Using init script, use `gradlew ... --init-script <path_to_your_init_script>` and in your script file put line like this one (see [init.workspace-ee-sample.gradle](init.workspace-ee-sample.gradle) for full example):
```
System.setProperty('org.gradle.project.propertyKey', 'propertyValue')
``` 

In command line, use `gradlew ... -PpropertyKey=propertyValue -PanotherPropertyKey=anotherPropertyValue ...` to provide custom value of one or more the properties. Please note the property values will be visible to other users on your system (in listing of running OS processes) and the entry will be also in your shell's history. For this reasons, it's recommended to use init script approach described in previous paragraph.

Following is the list of user-specific properties used by the Liferay Workspace EE build and their description:

| Property          | Default value | Sample custom value   | Required | Description   |
|---	            |---	        |---	                |---	   | ---           |
| awsAccessKey      | *not set*  	| AKIAJBDX3XAUXFBXWX5Q  | _Conditional_: only if you are building AMIs in AWS. | The AWS access key to access project's AWS account. The user owning the key has to have sufficient permissions, which are the same as [Packer requires](https://www.packer.io/docs/builders/amazon.html). If you want to clean old AMIs using the workspace, check [Cleaning old built AMIs from AWS](#Cleaning old built AMIs from AWS) below for additional permissions required. Used when interacting with AMI, like creating AMIs / -  `gradlew distBundleAmi` |
| awsSecretKey      | *not set*     | oRET8s0Oq0aU1fLt9A41zdRnBBta  | _Conditional_: only if you are building AMIs in AWS. | The AWS secret key belonging to access key above. Used when creating AMIs -  `gradlew distBundleAmi` |
| dockerExecutable  | docker        | /opt/docker_1.0/docker | _Conditional_: only if you are building Docker images _and_ you don't have 'docker' in PATH. | The resolvable path the Docker executable. Either simply `docker` (default), or absolute path to where Docker binary is installed on your local machine. Used for building Docker images with Liferay. |
| downloadBundleUserName  | *not set*        | john.doe | _Conditional_: only if the download URL requires authentication _and_ you don't have the project's bundle cached locally already. | The username to use to authenticate for the *liferay.workspace.bundle.url* URL. |
| downloadBundlePassword  | *not set*        | secretWord | _Conditional_: only if the download URL requires authentication _and_ you don't have the project's bundle cached locally already. | The password to use to authenticate for the *liferay.workspace.bundle.url* URL. |
| downloadPatchesUserName  | *not set*        | john.doe | _Conditional_: only if you don't have the defined project's patches cached locally already. | The username to use to authenticate for the download of the configured patches (see _liferay.workspace.ee.patches.download.and.install.patches_), typically from *files.liferay.com* (see *liferay.workspace.ee.patches.download.base.url*). |
| downloadPatchesPassword  | *not set*        | secretWord | _Conditional_: only if you don't have the defined project's patches cached locally already. | The password to use to authenticate for the download of the configured patches (see _liferay.workspace.ee.patches.download.and.install.patches_), typically from *files.liferay.com* (see *liferay.workspace.ee.patches.download.base.url*). |
| downloadOracleJdkUserName  | *not set*        | john.doe | _Conditional_: only if you don't have the defined project's JDK cached locally already _and_ the download requires Oracle credentials. | The username to use to authenticate for the download of the Oracle JDK from *oracle.com*. Only the latest update from major release can be downloaded publicly, older updates only with credentials. |
| downloadOracleJdkPassword  | *not set*        | secretWord | _Conditional_: only if you don't have the defined project's JDK cached locally already _and_ the download requires Oracle credentials. | The password to use to authenticate for the download of the Oracle JDK from *oracle.com*. Only the latest update from major release can be downloaded publicly, older updates only with credentials.  |
| jenkinsUserName   | *not set*     | jane.doe  | _Conditional_: only if you are using Jenkins tasks _and_ your Jenkins requires authentication. | The login for project's Jenkins server (see `liferay.workspace.ee.jenkins.server.url`). Used in tasks interacting with your Jenkins server, like `gradlew updateJenkinsItems`. | 
| jenkinsPassword   | *not set*     | janesSecretToken  | _Conditional_: only if you are using Jenkins tasks _and_ your Jenkins requires authentication. | The password / token for project's Jenkins server which was set up for `jenkinsUserName` in your Jenkins server. Used in tasks interacting with your Jenkins server, like `gradlew updateJenkinsItems`. |
| liferayRepositoryUserName   | *not set*     | john.doe  | _Conditional_: only if you are using tasks to upgrade workspace ee from Liferay repository. | The user name for Liferay's Nexus repository at `https://repository.liferay.com/nexus`. |
| liferayRepositoryPassword   | *not set*     | johnsSecretToken  | _Conditional_: only if you are using tasks to upgrade workspace ee from Liferay repository. | The password for Liferay's Nexus repository at `https://repository.liferay.com/nexus`. |
| packerExecutable  | packer        | /opt/packer_0.9.0_linux_amd64/packer  | _Conditional_: only if you are building AMIs or Docker images _and_ you don't have 'packer' in PATH. | The resolvable path the Packer executable. Either simply `packer` (default), or absolute path to where Packer binary is installed on your local machine. Used for building AMIs in AWS, so the same usage as for `awsAccessKey`.   |
| releaseNumber     | 1             | 17  | No | Incremental integer denoting the release number of this build. Useful for example in Jenkins, where you can ask job to do `gradlew -PreleaseNumber=$BUILD_NUMBER ...`. Used when building DEB or RPM packages (and AMIs since they are built from DEB ord RPM archives). |

### Other recommended settings (not strictly EE related, but strongly recommended)

#### rootProject.name (settings.gradle)

It is highly recommended to cement the name of your root project and not rely on Gradle to figure this out based on the name of your root directory. Liferay Workspace EE will use `rootProject.name` as package name for DEB / RPM archives. Root project's name can be set in [settings.gradle](settings.gradle):
```
rootProject.name = 'liferay-project-abc'
```

This prevents issues when users / CI will fetch your source code to a special directory not named after your project's assumed name. Choose reasonably short and self-explanatory name of your project, many artifacts produced by the build will be named after it.

#### project.version (build.gradle) 

It's also a good idea to think about versions of your project and set it explicitly in your root project's [build.gradle](build.gradle):
```
project.version = '1.0.0'
```

The default `project.version` in Gradle is String `undefined` (see [documentation](https://docs.gradle.org/current/dsl/org.gradle.api.Project.html#org.gradle.api.Project:version)). However, Liferay Workspace EE will use `0.0.0` if the version was not explicitly set, since `project.version` is used as package version for the DEB / RPM packages.

Increment your project's version as you add and release new features.


## Building Liferay bundle archives (ZIP and TAR)

This is a functionality of base Liferay Workspace. You can produce .zip with:
```
gradlew distBundleZip
```

In a similar way, you can produce .tar.gz with:
```
gradlew distBundleTar
```

Files will be created in [build]([build]) subdirectory of the root project and typically will be named like: 
* `${rootProject.name}.zip` / `.tar.gz`
    * if you don't have EE features installed)
* `${rootProject.name}.{environment}_{project.version}-${releaseNumber}.zip` / `.tar.gz`
    * with EE installed


## Building Liferay bundle for various project's environments

This is a functionality of base Liferay Workspace. The built bundle will include configs from subdirectory of [configs](configs) based on value of project property `liferay.workspace.environment`:
```
gradlew distBundleZip -Pliferay.workspace.environment=dev
```

Please note that configs from [configs/common](configs/common) will always be applied (for any built environment) and that they are applied first, before any environment-specific files are copied into the bundle.

Default environment for the project can be specified in [gradle.properties](gradle.properties). If not provided, it defaults to `local`.


## Building Linux packages (DEB and RPM)

Note: Only Tomcat bundles are supported for now. You need to make sure that `liferay.workspace.url` points to a Tomcat bundle with expected direcotry structure. If you select a unsupported bundle type (non-Tomcat one for now) using `liferay.workspace.ee.bundle.type` in [gradle.properties](gradle.properties) you won't be able to build DEB / RPM packages.

Your DEB packages, suited for Debian-based Linux systems (Debian, Ubuntu), can be built using:
```
gradlew distBundleDeb
```

Your RPM packages, suited for RedHat-based Linux systems (RHEL, CentOS, Fedora), can be built using:
```
gradlew distBundleRpm
```

Files will be created in [build]([build]) subdirectory of the root project. Both of these tasks use the product of `distBundleTar` - the tarball archive containing Liferay bundle. This archive is contained inside produced DEB / RPM package, together with installation / uninstallation scripts.

The tasks performed by DEB / RPM packages during installation of the package into OS are:

1. Creates user and group for Liferay ('liferay':'liferay') if they do not exist.
2. Extracts the bundle into FS (e.g. */opt/liferay/liferay-portal-tomcat* for Tomcat):
3. Installs startup script (e.g. */etc/init.d/liferay-tomcat* for Tomcat, see *liferay.workspace.ee.ospackage.liferay.service.name*)
    * start / stop / restart / status the bundle, using user 'liferay'
    * `JAVA_HOME` is explicitly set and used
    * `JAVA_HOME` is pointing to the place where JDK will be (or would be) installed by the package, see below
    * `PATH` is updated to contain our JDK and the first option - so app server / Liferay portal can run external Java processes using `java`
4. Installs log rotation config (e.g. */etc/logrotate.d/liferay-tomcat* for Tomcat, see *liferay.workspace.ee.ospackage.liferay.service.name*)
	* see [How to Rotate Tomcat catalina.out](https://dzone.com/articles/how-rotate-tomcat-catalinaout)
5. Liferay's service is enabled to auto-start on OS'es boot.
    * attempt is made to try as many known service implementations as possible (Upstart, SysVinit, Systemd etc.)
6. If 'liferay.workspace.ee.ospackage.jdk.installation.type' is set to 'oracle-jdk:bundled' or 'oracle-jdk:downloaded-on-install', then Oracle JDK is installed inside */opt/liferay* and symlinked as */opt/liferay/oracle-jdk-8*
    * Oracle JDK archive is downloaded during build and bundled into the resulting DEB / RPM
    * Liferay bundle should be run using this JDK, same way as the init.d script does it
    * for 'oracle-jdk:downloaded-on-install', the JDK is not bundled (in the .deb archive) but is downloaded when the DEB / RPM is installed into OS
        * this might be useful to keep the resulting .deb / .rpm archive smaller
7. If 'liferay.workspace.ee.ospackage.jdk.installation.type' is set to 'unmanaged', JDK (the "JAVA_HOME") will be expected in directory set by 'liferay.workspace.ee.ospackage.jdk.home'
    * may be empty indicating JDK ('java' command) will be available in PATH
    * it set, bin/java will be looked inside the directory as the Java executable

Note that Liferay Tomcat is not started after the package is installed, since it's not always desirable (like in the case of baking an AMI, see below). You need to start Liferay Tomcat manually (using the installed file */etc/init.d/liferay-tomcat*) or it will be started after next reboot of the OS.

The tasks performed by DEB / RPM packages during removal of the package into OS:

1. */etc/init.d/liferay-tomcat* script is removed from OS startup / shutdown runtime
2. */etc/init.d/liferay-tomcat* script is removed
3. the contents of */opt/liferay/liferay-portal-tomcat* are cleaned up
  * only the directory *data/* and file *portal-setup-wizard.properties* are left untouched, if present

Note the Oracle JDK 7 / 8 remains installed in the OS. Since we did not set any global environment variable pointing to this JDK, there is not need to remove the files.

### JDK setup and installation

Both `distBundleDeb` and `distBundleRpm` will produce packages which will attempt to install Oracle JDK 8, into */opt/liferay/oracle-jdk-8*, if there is no *bin/java* file under this path. Oracle JDK archive is downloaded during build and bundled in the resulting DEB / RPM. 

This path (*/opt/liferay/oracle-jdk-8*) is then passed to Liferay Tomcat bundle inside */etc/init.d/liferay-tomcat* as environment variable `JAVA_HOME=/opt/liferay/oracle-jdk-8`. File */etc/init.d/liferay-tomcat* is also installed into the OS from DEB / RPM, see above.

## Building Docker images

Note: Only Tomcat bundles are supported for now. You need to make sure that `liferay.workspace.url` points to a Tomcat bundle with expected direcotry structure. If you select a unsupported bundle type (non-Tomcat one for now) using `liferay.workspace.ee.bundle.type` in [gradle.properties](gradle.properties) you won't be able to build Docker images.

Your local Docker image can be built and tagged using:
```
gradlew distBundleDockerImageLocal
```

If you only want to build Dockerfile and not commit & tag the final image, you can use:
```
gradlew distBundleDockerfile
```

The build process of the Docker image has following steps:

1. OS package (.deb) with project's Liferay bundle is built by the 'ospackage' module
2. Packer is used to install this file and run some other setup & cleanup tasks
3. Packer tags the *raw* Docker image locally
	* this will produce Docker tag like: 
	
		```
		$ docker images
		REPOSITORY                     TAG                 IMAGE ID            CREATED             SIZE
        acme/liferay-workspace.local   0.0.0-1_raw         9df2cec53ea8        12 seconds ago      735.4 MB
        ```
    * the *-raw* suffix indicates that there is no metadata in this tag, only binary contents, since Packer does not use the Dockerfile syntax to produce the images
    * this tag can be either used with the help of our Dockerfile, built by the next step
4. Dockerfile is constructed and written
	* starting FROM the *-raw* tag built by Packer and adding all the metadata to start Liferay bundle
    * *maintainer*, *user*, *startup command* and *exposed ports* instructions as added
5. the Dockerfile is built & tagged into local Docker repository
	* **only** if you chose to run the *distBundleDockerImageLocal* task (not just the *distBundleDockerfile* task) 
    * this will produce the final Docker tag (e.g. *0.0.0-1*):
    
        ```
        $ docker images
        REPOSITORY                     TAG                 IMAGE ID            CREATED             SIZE
        acme/liferay-workspace.local   0.0.0-1             e101abc8b85f        11 seconds ago      735.4 MB
        acme/liferay-workspace.local   0.0.0-1_raw         9df2cec53ea8        12 seconds ago      735.4 MB
		```

The first part of the repository name (*acme*) can be customized with `liferay.workspace.ee.docker.repository.company` in gradle.properties. The tag value is built based on project's version and release number: 
* *0.0.0* is the version of the project, as computed by Liferay Workspace EE, defaulting to *0.0.0* in no Gradle project version was found. You can change this value in the root Gradle project (build.gradle) by setting e.g. `version = 1.0.1`. 
* *-1* is the release number specified for the current build. This is 1 by default and can be altered by passing e.g. `-PreleaseNumber=17` on command line when running the build.

The Packer step is used on purpose, even though we could just specify all the steps using (a slightly longer) Dockerfile. The reason is the size of the final image - it will be much smalled when built by Packer + minimalistic Dockerfile. Packer does all the installation in one Docker step, not increasing the size of the image with every installtion step. The difference is significant, image has about 740MB when built with Packer + Dockerfile vs. 1530 MB when built with Dockerfile only.

## Building AWS AMIs

Note: Only Tomcat bundles are supported for now. You need to make sure that `liferay.workspace.url` points to a Tomcat bundle with expected direcotry structure. If you select a unsupported bundle type (non-Tomcat one for now) using `liferay.workspace.ee.bundle.type` in [gradle.properties](gradle.properties) you won't be able to build DEB / RPM packages.

Your AMI can be built with `gradlew distBundleAmi --init-script init.gradle` where *init.gradle* contains at least the AWS credentials and valid path to Packer (if it is not available in PATH as `packer`). See [init.workspace-ee-sample.gradle] for sample.

You will need to make sure the AWS account to which the credentials belong has sufficient permissions. The AMI is being built by Packer, so the minimal permissions needed are equal to [Packer's requirements](https://www.packer.io/docs/builders/amazon.html#using-an-iam-instance-profile). Please note that workspace ee currently does not support IAM profiles (using credentials provided by the role assigned to the EC2 instance where the workspace ee is executed - e.g. Jenkins running in EC2 with AIM profile role set). You always have to provide AWS credentials explicitly.

You will also ou need to make sure the setup for Liferay Workspace EE is matching your AWS account and desired Linux OS running your Liferay bundles. Please see next section for details.

### Choosing the right base AMI for your needs

You can select from a wide variety of AMIs in EC2, so which one should you pick? First step is to find the base AMI, with clean installation of Linux OS. The rule of thumb is, go for the Linux distribution which you are most familiar with.

As a second step, you will need to tell the Liferay Workspace EE which AMI have you chosen and that it should be used to bake your project's AMIs with Liferay bundle installed inside, together with providing some basic details about this AMI, like SSH username and the type of packaging system used by its Linux OS.

Following are some sample configurations on how to set up your [gradle.properties] to produces the desired AMIs.

#### Debian-based AMI (Ubuntu) with default VPC available in region eu-central-1 (Frankfurt)

EE values in [gradle.properties]:
```
liferay.workspace.ee.aws.ami.primary.region=eu-central-1
liferay.workspace.ee.aws.ami.base.ami.id=ami-766d771a
```

These default values in [gradle.workspace-ee-defaults.properties] will complete your setup:
```
liferay.workspace.ee.aws.ami.base.ami.linux.packages.format=deb
liferay.workspace.ee.aws.ami.base.ami.ssh.user.name=ubuntu

liferay.workspace.ee.aws.ami.build.ec2.vpc.id=
liferay.workspace.ee.aws.ami.build.ec2.subnet.id=
```

#### Debian-based AMI (Ubuntu) without default VPC available, in region us-east-1 (N. Virginia)

Values in [gradle.properties]:
```
liferay.workspace.ee.aws.ami.build.ec2.vpc.id=vpc-63490f07
liferay.workspace.ee.aws.ami.build.ec2.subnet.id=subnet-48ad183e
```

These default values from [gradle.workspace-ee-defaults.properties] will complete your setup:
```
liferay.workspace.ee.aws.ami.primary.region=us-east-1
liferay.workspace.ee.aws.ami.base.ami.id=ami-5aa69030

liferay.workspace.ee.aws.ami.base.ami.linux.packages.format=deb
liferay.workspace.ee.aws.ami.base.ami.ssh.user.name=ubuntu
```


#### RedHat-based AMI (CentOS) with default VPC available in region eu-central-1 (Frankfurt)

EE values in [gradle.properties]:
```
liferay.workspace.ee.aws.ami.primary.region=eu-central-1
liferay.workspace.ee.aws.ami.base.ami.id=ami-2a868b37

liferay.workspace.ee.aws.ami.base.ami.linux.packages.format=rpm
liferay.workspace.ee.aws.ami.base.ami.ssh.user.name=centos

```

These default values in [gradle.workspace-ee-defaults.properties] will complete your setup:
```
liferay.workspace.ee.aws.ami.build.ec2.vpc.id=
liferay.workspace.ee.aws.ami.build.ec2.subnet.id=
```

#### RedHat-based AMI (CentOS) without default VPC available, in region us-east-1 (N. Virginia)

Values in [gradle.properties]:
```
liferay.workspace.ee.aws.ami.base.ami.id=ami-57cd8732

liferay.workspace.ee.aws.ami.base.ami.linux.packages.format=rpm
liferay.workspace.ee.aws.ami.base.ami.ssh.user.name=centos

liferay.workspace.ee.aws.ami.build.ec2.vpc.id=vpc-63490f07
liferay.workspace.ee.aws.ami.build.ec2.subnet.id=subnet-48ad183e
```

These default values from [gradle.workspace-ee-defaults.properties] will complete your setup:
```
liferay.workspace.ee.aws.ami.primary.region=us-east-1
```

### Cleaning old built AMIs from AWS

If you want to clean old project AMIs using workspace ee (see [gradle.workspace-ee-defaults.properties -> liferay.workspace.ee.aws.ami.clean.amis.*](gradle.workspace-ee-defaults.properties), you will need some extra permissions on top of the ones for Packer to build AMI. This is the extra permissions your AWS user will need, as IAM policy:

```json
{
    "Version": "2012-10-17",
        "Statement": [
          {
              "Effect":   "Allow",
              "Action":   [
                "ec2:DescribeImages",
                "ec2:DescribeInstances",
                "autoscaling:DescribeLaunchConfigurations",
                "ec2:DescribeSnapshots",
                
                "ec2:DeregisterImage",
                "ec2:DeleteSnapshot"
              ],
              "Resource": "*"
          }
        ]
}
```

## Managing Jenkins server items (jobs and views)

Liferay Workspace EE can help you with managing your Jenkins server. Once you have your project's Jenkins server up and running - accessible over HTTP(s) - your Liferay Workspace EE can interact with it using Jenkins REST API.

Your Jenkins server most likely has security enabled (enforces users to log in), which means unauthenticated users will not be able to perform too many action (if any). If this is the case, you will need to pass your Jenkins credentials to Liferay Workspace EE using init script. Jenkins tasks will need two project properties: `jenkinsUserName` and `jenkinsPassword`. Although you can pass these using `-P...` as well, it's strongly recommended to use init script: `gradlew ... --init-script=init.gradle` for yoru credentials to nto be recorded in shell's history.
 
Check [init.workspace-ee-sample.gradle](init.workspace-ee-sample) / [init.workspace-ee-sample-encrypted.gradle](init.workspace-ee-sample-encrypted) for details on how to write your own (private) init script and use it to provide credentials for Jenkins tasks.
 
If your Jenkins server is not secured and anonymous users can perform admin actions, you can set:

```
liferay.workspace.ee.jenkins.server.secure=false
```

in your [gradle.properties](gradle.properties) and Liferay Workspace EE will not require any Jenkins credentials to run Jenkins-related tasks. Please note this Jenkins setup is strongly discouraged, unless your Jenkins server is secured by other means, like being accessible only using private VPN connection.
 
You can set up your Jenkins server from the workspace using:
  ```
  gradlew initJenkinsServer
  ```

`initJenkinsServer` is a container task, it will delegate all work to two child tasks: `installJenkinsPlugins` and `createSampleItems`. Please see following sections for details.

### Jenkins plugins
 
`installJenkinsPlugins` will ask your Jenkins server to install several plugins, referenced by their name. These plugins are used by sample jobs (see below). If you do not wish to install the recommended plugins, only the jobs and views, use `createSampleItems` instead of `initJenkinsServer`.

**Note**: Make sure to restart your Jenkins server after _first successful_ run of `initJenkinsServer` task, since some of the installed plugins require restarting Jenkins server to take effect. You can use /safeRestart URI on your Jenkins to restart it from the UI.

### Jenkins items (jobs and views)

`initJenkinsServer` will also invoke `createSampleItems`, which reads local definition of sample Jenkins jobs and views and creates them in your Jenkins server. 

To check the list of items currently known to your workspace, use `gradlew listManagedJenkinsItems`.

#### Jobs

After installation of fresh workspace (EE), the project will contain a set of sample jobs for your workspace project. You can use this set of as a baseline for setting up CI - building your project's bundle .zip / .deb / .rpm / AMI (*build* jobs) and pushing it to remote server over SSH / using CloudFormation (*deploy* jobs).

`createSampleItems` will create 4 jobs  - samples (see below). These jobs will roughly perform these steps:

* *build-nnn*
	1. fetches sources from SCM
	2. invokes Gradle build of your workspace - producing .deb
	3. archives the built artifacts in Jenkins (build/*)	
* *deploy-nnn*
	1. copies artifacts from chosen build of previous job (.deb file)
	2. pushes this file to remote SSH server and used `dpkg` to install it
* *build-nnn_ami*
	1. fetches sources from SCM
	2. invokes Gradle build of your workspace - producing AMI in AWS
	3. archives the built artifacts in Jenkins (build/*, including CloudFormation template for appServers)	
* *deploy-nnn_ami*
	1. copies artifacts from chosen build of previous job (AMI ID, CloudFormation template)
	2. uses CloudFormation plugin with given template to redeploy the appServers stack using AMI ID produced by the previous build job 

Please note that you will need to finish the configuration of the jobs through your Jenkins server UI, for example to provide SCM credentials (and verify the URL you'll be using) or provide the IP and credentials for SSH connection to your target Liferay server. The description of each job contains TODOs with list of items your should check or update through your Jenkins UI.

Please note that the AMI-based jobs are optimized to be used with workspace EE's task `distBundleAmi` and the CloudFormation templates produced by liferay-in-cloud tool, version-controlled under _liferay-in-cloud/{environment}_ in your workspace sources. See the job's TODO comments in the description of the jobs.

#### Views

One view is defined in the workspace by default - _Samples_ - and grouping all the samples jobs listed above together.

## Backup & restore of Jenkins jobs & views

You can use your workspace to backup & restore your project's jobs & views (see previous sections) in your Jenkins server. The workflow is following:

1. You initialize your jobs and views in your server using `initJenkinsServer`
	* or just `createSampleItems` if you want to install your plugins manually, outside of the workspace
2. You finish the setup of your jobs using Jenkins server UI
	* cleanup, adjustments based on your project etc. -- see recommended TODOs in the jobs' description
3. You can backup your Jenkins jobs & views using `backupJenkinsItems`
	* this will create XMLs of all the items in *[workspace]/jenkins* directory
	* please note that **only the jobs known to the workspace will be dumped from Jenkins server** - the jobs and views listed in gradle.properties _liferay.workspace.ee.jenkins.managed.job.names_ and _liferay.workspace.ee.jenkins.managed.view.names_
	    * their default values include the sample jobs and view
	* if you need to backup additional jobs, add the jobs into the properties. You can choose to leave the sample jobs and view as managed or not, depending if you want them to be backed up back to your workspace
		* for example, if you have created additional jobs like *liferay-project-abc_deploy-prod-node-1* and *liferay-project-abc_deploy-prod-node-2* , you will want to add following into your [gradle.properties](gradle.properties):
		
            ```
            liferay.workspace.ee.jenkins.managed.job.names=\
                liferay-project-abc_deploy-prod-node-1,\
                liferay-project-abc_deploy-prod-node-2` 
            ```
5. You can use `restoreJenkinsItems` to restore items in Jenkins server based on local XMLs	stored in *[workspace]/jenkins* directory	

## Limitation - CSRF protection in Jenkins

If you have CSRF protection enabdle in Jenkins (this seems to be the default starting with Jenkins 2.0), you will most 
likely see errors like this one when running any Jenkins-related tasks:

    403: No valid crumb was included in the request
     
The full HTML respose from Jenkins will look like this:
    
    <html>
        <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
        <title>Error 403 No valid crumb was included in the request</title>
        </head>
        <body><h2>HTTP ERROR 403</h2>
        <p>Problem accessing //pluginManager/installNecessaryPlugins. Reason:
        <pre>    No valid crumb was included in the request</pre></p><hr><i><small>Powered by Jetty://</small></i><hr/>
        
        </body>
    </html>

This means you have CSRF protection enabled. Unfortunately, our `jenkins` module cannot yet get around this security 
measure. The only option for now is disabling CSRF in Jenkins as advised in this issue:
* https://github.com/ghale/gradle-jenkins-plugin/issues/78

This limitation will be removed in one of future releases of liferay-workspace-ee


## Integration of Liferay Workspace EE with base Liferay Workspace

The main integration point is file [settings.gradle](settings.gradle), which in case of EE features installed should contain line:
```
apply from: 'gradle/liferay-workspace-ee/settings-ee.gradle'
```

This will instruct Gradle to load given script during initialization phase, before any projects are evaluated or tasks being executed. This script will configures all separate EE subprojects of the root Liferay Workspace Build, which contain all EE features. The EE subprojects' files are organized inside [gradle/liferay-workspace-ee](gradle/liferay-workspace-ee).

[gradle.workspace-ee-defaults.properties](gradle.workspace-ee-defaults.properties) lists all EE properties used by the build and can be overridden using standard [gradle.properties](gradle.properties), see above. If you do not provide custom value in project's [gradle.properties](gradle.properties), the default values as specified in file [gradle.workspace-ee-defaults.properties](gradle.workspace-ee-defaults.properties) will be loaded and used by the build.

[init.workspace-ee-sample.gradle](init.workspace-ee-sample.gradle) lists all EE properties used by the build, which users can use to pass sensitive / user-specific information to the build script, see above. Most of these properties do not have default values, so if you use any task which needs these properties, the build will fail and prompt you to provide valid values of the necessary properties. Each user should create his / her own version of the file, called e.g. *init.gradle*, use it to run the local builds and never push this file into the CSM repository.


## Customizing Liferay Workspace EE scripts (discouraged)

All the scripts which implement the Liferay Workspace EE features are installed inside [gradle/liferay-workspace-ee](gradle/liferay-workspace-ee). Ideally, you shoudl not have any need to customize any of these, the necessary configurations can be provided to the build using either gradle.properties (keys liferay.workspace.ee.*) or on command line / init script (see complete list above). If you customize any scripts, it will be harder for you to upgrade to newer version of Liferay Workspace EE in the future.

However, if you feel confident to change the scripts, here are some basic rules you should follow:

1. Learn Gradle (and Groovy) first, to understand how the build system was designed. Gradle is very powerful and differs from both Ant or Maven significantly, so make sure you know at least the basics.
2. Version-control all your Liferay Workspace files (which is a good idea anyway, for any source code).
3. Do not update file [gradle.workspace-ee-defaults.properties](gradle.workspace-ee-defaults.properties), you can override all properties using [gradle.properties](gradle.properties). File [gradle.workspace-ee-defaults.properties](gradle.workspace-ee-defaults.properties) will be overwritten by Liferay Workspace EE installer when you run `upgrade` in the future.
4. Do not update file [init.workspace-ee-sample.gradle](init.workspace-ee-sample.gradle), every user should create his / her own (private) version of this file (e.g. *init.gradle*) and use it for local builds where necessary. You can also pass the properties on command line, using `-P...`, but remember these will be visible to other users (in listing of running OS processes) and will also remain in the history of your shell. File [init.workspace-ee-sample.gradle](init.workspace-ee-sample.gradle) will be overwritten by Liferay Workspace EE installer when you run `upgrade` in the future.
5. Do not alter the Liferay Workspace EE's `apply from ...` line in [settings.gradle](settings.gradle), it should read:
	```
	// Liferay Workspace EE START
	apply from: 'gradle/liferay-workspace-ee/settings-ee.gradle'
	// Liferay Workspace EE END
	```
    Liferay Workspace EE installer will look for this line to determine if EE features were installed in base Liferay Workspace or not.
 
6. When changing some script / file from Liferay Workspace EE (inside [gradle/liferay-workspace-ee](gradle/liferay-workspace-ee)), clearly mark the customization (its start and end line) in the file and describe its purpose, for example:

	```
	... other uncustomized code...
	
	// CUSTOM BEGIN
	// Change the path where Liferay bundle tar is extracted inside DEB / RPM
	
	... your customized code...
	
	// CUSTOM END
	
	...other uncustomized code...
	```
This will allow you to upgrade your customization later, by manually merging your custom code into the new version of the file, coming from new version of Liferay Workspace EE.