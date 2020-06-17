import { Task } from 'graphile-worker';

import { SendEmailPayload, dateFormat, numberFormat } from './send_email';

interface CreditsTransferSendConfirmationPayload {
  purchaseId: string;
  ownerName: string;
  project: {
    name: string;
    image: string;
    location: {
      place_name: string;
    };
    area: number;
    areaUnit: string;
    metadata: {
      url: string;
    };
  };
  creditClass: {
    name: string;
    metadata: {
      type: string;
    };
  };
  quantity: number;
  amount: number;
  currency: string;
  email: string;
}

const task: Task = async (inPayload, { addJob }) => {
  const {
    email,
    purchaseId,
    ownerName,
    project,
    creditClass,
    quantity,
    amount,
    currency,
  }: CreditsTransferSendConfirmationPayload = inPayload as any;
  const sendEmailPayload: SendEmailPayload = {
    options: {
      to: email,
      subject: "Your Regen Registry purchase was successful",
    },
    template: "confirm_credits_transfer.mjml",
    variables: {
      purchaseId,
      ownerName,
      projectName: project.name,
      projectImage: project.image,
      projectLocation: project.location.place_name,
      projectArea: project.area,
      projectAreaUnit: project.areaUnit,
      projectLink: project.metadata.url,
      creditClassName: creditClass.name,
      creditClassType: creditClass.metadata.type,
      quantity,
      amount: numberFormat.format(amount),
      currency: currency.toUpperCase(),
      date: dateFormat.format(new Date()),
    },
  };
  await addJob('send_email', sendEmailPayload);
};

export default task;
