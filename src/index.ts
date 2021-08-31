import awsLambda from 'aws-lambda';
import nodemailer from 'nodemailer';

const sender = '???@gmail.com';
const senderPassword = '';
const receivers = `???@gmail.com`;

let transporter = nodemailer.createTransport({
    host: "smtp.gmail.com",
    port: 465,
    secure: true, // true for 465, false for other ports
    auth: {
        user: sender,
        pass: senderPassword,
    },
});

exports.handler = async (event: awsLambda.APIGatewayProxyEventV2, context: any): Promise<awsLambda.APIGatewayProxyResultV2> => {
    let response: awsLambda.APIGatewayProxyResult;
    try {
        const path = event.requestContext.http.path;
        const data = JSON.parse(event.body!);

        await transporter.sendMail({
            from: `bug-report-mailer`,
            to: receivers,
            subject: data.subject,
            text: data.text,
        });

        response = {
            statusCode: 200,
            body: JSON.stringify('Success!'),
        };
    } catch (err) {
        response = {
            statusCode: 400,
            body: JSON.stringify(`Error! ${err}\n${JSON.stringify(event)}`),
        };
    }
    return response;
};
