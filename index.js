import express from 'express'
const app = express()

app.use(express.static('pages'))

app.listen(80)