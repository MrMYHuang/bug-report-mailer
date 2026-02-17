import nodemailer from 'nodemailer';
import params from "../params.json";

const sender = 'mr.myhuang@gmail.com';
const senderPassword = params.senderPassword;
const receivers = `myh@live.com`;

let transporter = nodemailer.createTransport({
    host: 'smtp.gmail.com',
    port: 465,
    secure: true, // true for 465, false for other ports
    auth: {
        user: sender,
        pass: senderPassword,
    },
});

exports.handler = async (event: any) => {
    let response = {
        statusCode: 200,
        body: '',
    };

    try {
        const data = (event) as any;

        await transporter.sendMail({
            from: `${sender}`,
            to: receivers,
            subject: data.subject,
            text: data.text,
        });

        const msg = 'Success!';
        response = {
            statusCode: 200,
            body: JSON.stringify(msg),
        };
        console.log(msg);
    } catch (err) {
        const errMsg = JSON.stringify(`Error! ${err}\n${JSON.stringify(event)}`);
        response = {
            statusCode: 400,
            body: errMsg,
        };
        console.error(errMsg);
    }
    return response;
};
