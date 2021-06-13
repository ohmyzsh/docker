const fs = require('fs')
const https = require('https')

// GitHub Action workflow message utils
const actions = {
  debug(message) {
    console.log(`::debug::${message}`)
  },
  error(message) {
    console.log(`::error ::${message}`)
  },
  warning(message) {
    console.log(`::warning ::${message}`)
  }
}

/**
 * Wrapper around https.request that follows redirects.
 * @author Marc Cornellà <hello@mcornella.com>
 * @param {string} url URL to send the request to.
 * @param {https.RequestOptions} options Request options, including method and headers.
 * @param {string} body Optionally send a body.
 * @returns A Promise that resolves when a response is received.
 */
function request(url, options, body) {
  return new Promise((resolve, reject) => {
    const req = https.request(url, options, res => {
      res.setEncoding('utf-8')

      actions.debug(JSON.stringify({ url, options, body, statusCode: res.statusCode, headers: res.headers }))

      // Run the request again against the new URL
      if ([301, 302, 307, 308].includes(res.statusCode) && res.headers.location) {
        return request(res.headers.location, options, body)
          .then(resolve)
          .catch(reject)
      }

      res.on('data', data => {
        if (res.statusCode !== 200) reject(data)
        else resolve(data)
      })
    })

    req.on('error', reject)

    if (body) req.write(body)
    req.end()
  })
}

/**
 * Makes a request to the Docker Hub API to receive a token
 * for authenticated API calls.
 * @param {string} username Username for Docker Hub.
 * @param {string} password Password or access token for Docker Hub.
 * @returns A Promise that resolves with the API token if the call succeeds.
 */
function getToken(username, password) {
  const url = `https://hub.docker.com/v2/users/login`
  const body = JSON.stringify({ username, password })
  const options = {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Content-Length': Buffer.byteLength(body),
    }
  }

  return request(url, options, body).then(res => {
    const json = JSON.parse(res)
    if (!json.token) throw json
    else return json.token
  })
}

/**
 * Makes a PATCH request to the Docker Hub API to update the README content
 * of the passed repository.
 * @param {string} token Docker Hub API authentication token.
 * @param {string} repository Repository for Docker image.
 * @param {string} readme README content in Markdown syntax.
 * @returns A Promise that resolves when the API call succeeds.
 */
function updateRepositoryReadme(token, repository, readme) {
  const url = `https://hub.docker.com/v2/repositories/${repository}/`
  const body = JSON.stringify({ full_description: readme })
  const options = {
    method: 'PATCH',
    headers: {
      'Content-Type': 'application/json',
      'Content-Length': Buffer.byteLength(body),
      'Authorization': `JWT ${token}`
    }
  }

  return request(url, options, body)
}

// Get input arguments
const REPOSITORY = process.argv[2]
const README = process.argv[3]

if (!REPOSITORY || !README) {
  actions.error('Missing Docker Hub repository and path to README file')
  process.exit(1)
}

// Get README file contents
if (!fs.existsSync(README)) {
  actions.error(`README file does not exist (at ${README})`)
  process.exit(1)
}

const ReadmeContent = fs.readFileSync(README).toString('utf-8')

// Get Docker Hub credentials
const USERNAME = process.env.DH_USERNAME
const PASSWORD = process.env.DH_PASSWORD

if (!USERNAME || !PASSWORD) {
  actions.error('Missing environment variable credentials')
  process.exit(1)
}

// Get API token and then update README for Docker Hub repository
getToken(USERNAME, PASSWORD)
  .then(token => updateRepositoryReadme(token, REPOSITORY, ReadmeContent))
  .then(res => actions.debug(res))
  .catch(err => actions.error(err))
